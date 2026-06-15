import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/data/repositories/coupon/coupon_repository.dart';
import 'package:med/features/shop/models/coupon_model.dart';
import 'package:med/features/shop/models/user_coupon_model.dart';

/// GetX controller for the entire coupon lifecycle on the user side.
class CouponController extends GetxController {
  static CouponController get instance => Get.find();

  final _repo = CouponRepository.instance;

  // ── State ─────────────────────────────────────────────────────────────────

  /// All UserCoupons for current user (real-time stream).
  final RxList<UserCouponModel> userCoupons = <UserCouponModel>[].obs;

  /// The coupon currently applied at checkout.
  final Rx<CouponModel?> appliedCoupon = Rx<CouponModel?>(null);
  final Rx<UserCouponModel?> appliedUserCoupon = Rx<UserCouponModel?>(null);
  final RxDouble discountAmount = 0.0.obs;
  final RxDouble finalTotal = 0.0.obs;

  /// Coupon code text-field controller (checkout screen).
  final couponCodeController = TextEditingController();
  final RxBool isApplying = false.obs;
  final RxString couponError = ''.obs;
  final RxString couponSuccess = ''.obs;

  /// Live discount values fetched from the `Coupons` collection.
  /// Key = coupon code (UPPER), Value = actual discount value from Firestore.
  /// Used to fix stale-zero display in wallet chips.
  final RxMap<String, double> _liveDiscounts = <String, double>{}.obs;

  /// Per-user redemption limits fetched from the `Coupons` collection.
  /// Key = coupon code (UPPER), Value = perUserLimit from Firestore.
  final RxMap<String, int> _perUserLimits = <String, int>{}.obs;

  /// This user's redemption counts fetched from `CouponRedemptions`.
  /// Key = couponId (Firestore doc ID), Value = number of times redeemed.
  final RxMap<String, int> _myUsageCounts = <String, int>{}.obs;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _listenToUserCoupons();
  }

  @override
  void onClose() {
    couponCodeController.dispose();
    super.onClose();
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  List<UserCouponModel> get pendingCoupons =>
      userCoupons.where((uc) => uc.isPending).toList();

  List<UserCouponModel> get walletCoupons =>
      userCoupons.where((uc) => uc.isAccepted && !uc.isExpired).toList();

  bool get hasCouponApplied => appliedCoupon.value != null;

  /// Returns the live discount value for [code] from the `Coupons` collection.
  /// Falls back to the stale value stored on the UserCoupon document.
  double liveDiscountFor(UserCouponModel uc) {
    final live = _liveDiscounts[uc.couponCode.toUpperCase()];
    return live ?? uc.discountValue;
  }

  String liveDiscountLabelFor(UserCouponModel uc) {
    final value = liveDiscountFor(uc);
    return uc.discountType == 'PERCENTAGE'
        ? '${value.toStringAsFixed(0)}% OFF'
        : 'Rs ${value.toStringAsFixed(0)} OFF';
  }

  /// Per-user usage limit for [uc] from the Coupons collection cache.
  int perUserLimitFor(UserCouponModel uc) =>
      _perUserLimits[uc.couponCode.toUpperCase()] ?? 1;

  /// How many times the current user has already redeemed coupon [uc].
  int myUsageCountFor(UserCouponModel uc) => _myUsageCounts[uc.couponId] ?? 0;

  /// Remaining uses the current user has for coupon [uc].
  /// Returns 999 when perUserLimit == 0 (unlimited).
  int usesLeftFor(UserCouponModel uc) {
    final limit = perUserLimitFor(uc);
    if (limit <= 0) return 999;
    return (limit - myUsageCountFor(uc)).clamp(0, limit);
  }

  // ── Real-time listener ────────────────────────────────────────────────────

  void _listenToUserCoupons() {
    if (_uid.isEmpty) return;
    _repo.streamUserCoupons().listen((list) {
      userCoupons.value = list;
      // Eagerly refresh live discounts and per-user limits
      _refreshLiveDiscounts(list);
      // Refresh this user's redemption counts for "uses left" display
      _refreshUsageCounts(list);
      // Silently write EXPIRED status for any overdue coupons
      _expireOverdueCoupons(list);
    });
  }

  /// Detects ACCEPTED/PENDING coupons whose ExpiresAt has passed and marks
  /// them as EXPIRED in Firestore. Runs in background — failures are silent.
  Future<void> _expireOverdueCoupons(List<UserCouponModel> list) async {
    final now = DateTime.now();
    final overdue = list.where(
      (uc) =>
          (uc.status == 'ACCEPTED' || uc.status == 'PENDING') &&
          uc.expiresAt != null &&
          now.isAfter(uc.expiresAt!),
    );
    for (final uc in overdue) {
      try {
        await _repo.expireUserCoupon(uc.id);
      } catch (_) {
        // Non-critical — UI already hides them via isExpired getter
      }
    }
  }

  /// For any wallet coupon whose stored discountValue is 0, fetch the real
  /// value from the `Coupons` collection and cache it locally.
  /// Also caches perUserLimit for "uses left" display.
  /// All fetches run in parallel via Future.wait.
  Future<void> _refreshLiveDiscounts(List<UserCouponModel> list) async {
    final toFetch = list
        .where(
          (uc) =>
              uc.isAccepted &&
              !uc.isExpired &&
              uc.couponCode.isNotEmpty &&
              !_liveDiscounts.containsKey(uc.couponCode.toUpperCase()),
        )
        .map((uc) => uc.couponCode.toUpperCase())
        .toSet();

    if (toFetch.isEmpty) return;

    await Future.wait(
      toFetch.map((code) async {
        try {
          final coupon = await _repo.fetchCouponByCode(code);
          if (coupon != null) {
            if (coupon.discountValue > 0) {
              _liveDiscounts[code] = coupon.discountValue;
            }
            // Cache per-user limit so the wallet can show "X uses left"
            _perUserLimits[code] = coupon.perUserLimit;
          }
        } catch (_) {
          // Non-critical — display will use stored value as fallback
        }
      }),
    );
  }

  /// Fetches this user's redemption counts for each active wallet coupon
  /// and caches them reactively for "uses left" display.
  Future<void> _refreshUsageCounts(List<UserCouponModel> list) async {
    final toFetch = list
        .where(
          (uc) =>
              (uc.isAccepted || uc.isPending) &&
              uc.couponId.isNotEmpty &&
              !_myUsageCounts.containsKey(uc.couponId),
        )
        .map((uc) => uc.couponId)
        .toSet();

    if (toFetch.isEmpty) return;

    await Future.wait(
      toFetch.map((couponId) async {
        try {
          final count = await _repo.getUserRedemptionCount(couponId);
          _myUsageCounts[couponId] = count;
        } catch (_) {}
      }),
    );
  }

  // ── Apply coupon from text field (checkout) ────────────────────────────────

  Future<void> applyFromTextField({
    required double subtotal,
    required double shippingFee,
    required double taxFee,
  }) async {
    final code = couponCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      couponError.value = 'Please enter a coupon code.';
      return;
    }
    await applyCouponCode(
      code: code,
      subtotal: subtotal,
      shippingFee: shippingFee,
      taxFee: taxFee,
    );
  }

  /// Apply a coupon from the wallet (user already accepted it).
  Future<void> applyCouponFromWallet({
    required UserCouponModel userCoupon,
    required double subtotal,
    required double shippingFee,
    required double taxFee,
  }) async {
    await applyCouponCode(
      code: userCoupon.couponCode,
      subtotal: subtotal,
      shippingFee: shippingFee,
      taxFee: taxFee,
      preloadedUserCoupon: userCoupon,
    );
  }

  Future<void> applyCouponCode({
    required String code,
    required double subtotal,
    required double shippingFee,
    required double taxFee,
    UserCouponModel? preloadedUserCoupon,
  }) async {
    if (_uid.isEmpty) return;
    couponError.value = '';
    couponSuccess.value = '';
    isApplying.value = true;

    try {
      // 1. Fetch coupon from Firestore
      final coupon = await _repo.fetchCouponByCode(code);
      if (coupon == null) {
        couponError.value = 'Coupon code not found or inactive.';
        return;
      }

      // 2. Validity checks (no API needed)
      final now = DateTime.now();
      if (!coupon.isActive) {
        couponError.value = 'This coupon is no longer active.';
        return;
      }
      if (coupon.startDate != null && now.isBefore(coupon.startDate!)) {
        couponError.value = 'This coupon is not valid yet.';
        return;
      }
      if (coupon.endDate != null && now.isAfter(coupon.endDate!)) {
        couponError.value = 'This coupon has expired.';
        return;
      }
      if (coupon.usageLimit > 0 && coupon.usageCount >= coupon.usageLimit) {
        couponError.value = 'This coupon has reached its usage limit.';
        return;
      }
      if (subtotal < coupon.minOrderAmount) {
        couponError.value =
            'Minimum order of Rs ${coupon.minOrderAmount.toStringAsFixed(0)} required.';
        return;
      }

      // 3. Per-user redemption limit
      if (coupon.perUserLimit > 0) {
        final redemptionCount = await _repo.getUserRedemptionCount(coupon.id);
        if (redemptionCount >= coupon.perUserLimit) {
          couponError.value = 'You have already used this coupon.';
          return;
        }
      }

      // 4. Calculate discount
      double discount;
      if (coupon.type.toUpperCase() == 'PERCENTAGE') {
        discount = subtotal * (coupon.discountValue / 100.0);
      } else {
        discount = coupon.discountValue;
      }
      if (discount > subtotal) discount = subtotal;
      discount = double.parse(discount.toStringAsFixed(2));
      final total = subtotal + shippingFee + taxFee - discount;

      // 5. Apply locally
      appliedCoupon.value = coupon;
      appliedUserCoupon.value = preloadedUserCoupon;
      discountAmount.value = discount;
      finalTotal.value = total < 0 ? 0 : total;

      // Cache live discount for display
      _liveDiscounts[coupon.code.toUpperCase()] = coupon.discountValue;

      couponSuccess.value = coupon.type.toUpperCase() == 'PERCENTAGE'
          ? '${coupon.discountValue.toStringAsFixed(0)}% discount applied! '
                'You save Rs ${discount.toStringAsFixed(0)}.'
          : 'Rs ${discount.toStringAsFixed(0)} discount applied!';
      couponCodeController.text = code;
    } catch (e) {
      couponError.value = 'Failed to apply coupon. Please try again.';
    } finally {
      isApplying.value = false;
    }
  }

  // ── Remove applied coupon ─────────────────────────────────────────────────

  void removeCoupon() {
    appliedCoupon.value = null;
    appliedUserCoupon.value = null;
    discountAmount.value = 0.0;
    finalTotal.value = 0.0;
    couponError.value = '';
    couponSuccess.value = '';
    couponCodeController.clear();
  }

  // ── Accept coupon from notification ───────────────────────────────────────

  Future<void> acceptCoupon(UserCouponModel uc) async {
    try {
      await _repo.acceptUserCoupon(uc.id);
      final idx = userCoupons.indexWhere((e) => e.id == uc.id);
      if (idx != -1) {
        userCoupons[idx] = uc.copyWith(
          status: 'ACCEPTED',
          acceptedAt: DateTime.now(),
        );
      }
      Get.snackbar(
        '🎉 Coupon Accepted',
        'Code "${uc.couponCode}" added to your wallet!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to accept coupon.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── Decline coupon from notification ──────────────────────────────────────

  Future<void> declineCoupon(UserCouponModel uc) async {
    try {
      await _repo.declineUserCoupon(uc.id);
      final idx = userCoupons.indexWhere((e) => e.id == uc.id);
      if (idx != -1) {
        userCoupons[idx] = uc.copyWith(
          status: 'DECLINED',
          declinedAt: DateTime.now(),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to decline coupon.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── Redeem coupon after order is placed ───────────────────────────────────

  Future<bool> redeemAppliedCoupon(String orderId) async {
    final coupon = appliedCoupon.value;
    if (coupon == null) return true; // No coupon — not an error

    try {
      // 1. Record redemption in Firestore
      await _repo.recordRedemption(
        couponId: coupon.id,
        couponCode: coupon.code,
        orderId: orderId,
        discountAmount: discountAmount.value,
      );

      // 2. Update wallet status based on per-user limit
      final uc = appliedUserCoupon.value;
      if (uc != null) {
        // Fetch fresh count from Firestore after recording to ensure accuracy
        final newCount = await _repo.getUserRedemptionCount(coupon.id);
        // Update local cache immediately so "uses left" re-renders
        _myUsageCounts[coupon.id] = newCount;

        final limitReached =
            coupon.perUserLimit > 0 && newCount >= coupon.perUserLimit;

        if (limitReached) {
          // Limit hit → mark REDEEMED → coupon disappears from the wallet
          await _repo.redeemUserCoupon(uc.id);
        }
        // Limit NOT reached → leave ACCEPTED → stays in wallet for next use
      }

      removeCoupon();
      return true;
    } catch (e) {
      return false;
    }
  }
}
