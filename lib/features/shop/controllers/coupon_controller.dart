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

  // ── Real-time listener ────────────────────────────────────────────────────

  void _listenToUserCoupons() {
    if (_uid.isEmpty) return;
    _repo.streamUserCoupons().listen((list) {
      userCoupons.value = list;
    });
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

      // 4. Calculate discount in Dart
      double discount;
      if (coupon.type.toUpperCase() == 'PERCENTAGE') {
        discount = subtotal * (coupon.discountValue / 100.0);
      } else {
        discount = coupon.discountValue;
      }
      // Discount cannot exceed the subtotal
      if (discount > subtotal) discount = subtotal;
      discount = double.parse(discount.toStringAsFixed(2));
      final total = subtotal + shippingFee + taxFee - discount;

      // 5. Apply locally
      appliedCoupon.value = coupon;
      appliedUserCoupon.value = preloadedUserCoupon;
      discountAmount.value = discount;
      finalTotal.value = total < 0 ? 0 : total;
      couponSuccess.value = coupon.type.toUpperCase() == 'PERCENTAGE'
          ? '${coupon.discountValue.toStringAsFixed(0)}% discount applied! You save Rs ${discount.toStringAsFixed(0)}.'
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
      // Record redemption directly in Firestore — no FastAPI needed
      await _repo.recordRedemption(
        couponId: coupon.id,
        couponCode: coupon.code,
        orderId: orderId,
        discountAmount: discountAmount.value,
      );

      // Mark the UserCoupon doc as REDEEMED if one was used from wallet
      final uc = appliedUserCoupon.value;
      if (uc != null) {
        await _repo.redeemUserCoupon(uc.id);
      }

      removeCoupon();
      return true;
    } catch (e) {
      return false;
    }
  }
}
