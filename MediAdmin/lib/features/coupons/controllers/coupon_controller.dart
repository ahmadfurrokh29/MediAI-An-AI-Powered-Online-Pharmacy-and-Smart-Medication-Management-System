import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/campaign_model.dart';
import '../models/coupon_model.dart';

// FastAPI URL — only used for optional FCM push in sendCampaign.
const String _kApiBase = 'http://127.0.0.1:8000';

class CouponController extends GetxController {
  static CouponController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<CouponModel> coupons = <CouponModel>[].obs;
  final RxList<CampaignModel> campaigns = <CampaignModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool hasInitialized = false.obs;

  // Analytics
  final RxInt totalRedemptions = 0.obs;
  final RxDouble totalDiscountGiven = 0.0.obs;
  final RxDouble acceptanceRate = 0.0.obs;
  final RxDouble declineRate = 0.0.obs;

  Future<void> initialize() async {
    if (!hasInitialized.value) {
      await Future.wait([fetchCoupons(), fetchCampaigns(), fetchAnalytics()]);
      hasInitialized.value = true;
    }
  }

  List<CouponModel> get filteredCoupons {
    if (searchQuery.value.isEmpty) return coupons;
    final q = searchQuery.value.toLowerCase();
    return coupons
        .where(
          (c) =>
              c.code.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q) ||
              c.type.toLowerCase().contains(q),
        )
        .toList();
  }

  // ── Fetch Coupons ──────────────────────────────────────────────────────────

  Future<void> fetchCoupons() async {
    try {
      isLoading.value = true;
      final snapshot = await _db
          .collection('Coupons')
          .orderBy('CreatedAt', descending: true)
          .get();
      coupons.value = snapshot.docs
          .map((doc) => CouponModel.fromSnapshot(doc))
          .toList();

      // Silently deactivate any coupons whose EndDate has passed.
      // Runs after the list is set so the admin sees the correct state
      // immediately — no extra refresh needed.
      await _autoExpireOldCoupons();
    } catch (e) {
      // Don't clear existing data — just inform the admin; list stays intact.
      if (coupons.isEmpty) {
        Get.snackbar(
          'Info',
          'No coupons found. Create a new coupon.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Batch-writes `IsActive: false` to every coupon whose `EndDate` is in the
  /// past, then updates the in-memory list so the UI reflects it immediately.
  Future<void> _autoExpireOldCoupons() async {
    final now = DateTime.now();
    final toExpire = coupons
        .where(
          (c) => c.isActive && c.endDate != null && now.isAfter(c.endDate!),
        )
        .toList();

    if (toExpire.isEmpty) return;

    try {
      final batch = _db.batch();
      for (final c in toExpire) {
        batch.update(_db.collection('Coupons').doc(c.id), {
          'IsActive': false,
          'UpdatedAt': Timestamp.now(),
        });
      }
      await batch.commit();

      // Reflect the change in-memory so the UI updates without a re-fetch
      final expiredIds = toExpire.map((c) => c.id).toSet();
      for (int i = 0; i < coupons.length; i++) {
        if (expiredIds.contains(coupons[i].id)) {
          coupons[i] = coupons[i].copyWith(isActive: false);
        }
      }
    } catch (_) {
      // Non-critical — isEffectivelyActive getter covers the UI fallback
    }
  }

  // ── Create Coupon ──────────────────────────────────────────────────────────

  Future<void> createCoupon(CouponModel coupon) async {
    try {
      isLoading.value = true;
      final docRef = await _db.collection('Coupons').add(coupon.toJson());
      coupons.insert(0, coupon.copyWith(id: docRef.id));
      Get.snackbar(
        'Success',
        'Coupon created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create coupon: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Update Coupon ──────────────────────────────────────────────────────────

  Future<void> updateCoupon(CouponModel coupon) async {
    try {
      isLoading.value = true;
      await _db
          .collection('Coupons')
          .doc(coupon.id)
          .update(coupon.copyWith(updatedAt: DateTime.now()).toJson());
      final index = coupons.indexWhere((c) => c.id == coupon.id);
      if (index != -1) {
        coupons[index] = coupon.copyWith(updatedAt: DateTime.now());
      }
      Get.snackbar(
        'Success',
        'Coupon updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update coupon: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Toggle Active ──────────────────────────────────────────────────────────

  Future<void> toggleActive(String couponId, bool isActive) async {
    try {
      await _db.collection('Coupons').doc(couponId).update({
        'IsActive': isActive,
        'UpdatedAt': Timestamp.now(),
      });
      final index = coupons.indexWhere((c) => c.id == couponId);
      if (index != -1) {
        coupons[index] = coupons[index].copyWith(isActive: isActive);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update status: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── Delete Coupon ──────────────────────────────────────────────────────────

  Future<void> deleteCoupon(String couponId) async {
    try {
      await _db.collection('Coupons').doc(couponId).delete();
      coupons.removeWhere((c) => c.id == couponId);
      Get.snackbar(
        'Success',
        'Coupon deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete coupon: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── Campaigns ─────────────────────────────────────────────────────────────

  Future<void> fetchCampaigns() async {
    try {
      final snap = await _db
          .collection('Campaigns')
          .orderBy('CreatedAt', descending: true)
          .get();
      campaigns.value = snap.docs
          .map((doc) => CampaignModel.fromSnapshot(doc))
          .toList();
    } catch (_) {
      campaigns.value = [];
    }
  }

  Future<void> createCampaign(CampaignModel campaign) async {
    try {
      isLoading.value = true;
      final docRef = await _db.collection('Campaigns').add(campaign.toJson());
      campaigns.insert(0, campaign.copyWith(id: docRef.id));
      Get.snackbar(
        'Success',
        'Campaign created.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create campaign: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Send a campaign:
  /// 1. Fetch the coupon details (DiscountValue, Type, Description).
  /// 2. Resolve target user IDs from Firestore.
  /// 3. Write a UserCoupons doc for every user (Firestore batch, idempotent).
  /// 4. Try to trigger FCM push via FastAPI — non-blocking, failure is silent.
  /// 5. Mark campaign as ACTIVE in Firestore.
  Future<void> sendCampaign(CampaignModel campaign) async {
    try {
      isLoading.value = true;

      // ── 1. Fetch coupon details so wallet shows correct discount ─────────
      double couponDiscountValue = 0.0;
      String couponDiscountType = 'FLAT';
      String couponDescription = '';
      Timestamp? couponExpiresAt;

      final couponDoc = await _db
          .collection('Coupons')
          .doc(campaign.couponId)
          .get();
      if (couponDoc.exists) {
        final d = couponDoc.data()!;
        couponDiscountValue = (d['DiscountValue'] ?? 0).toDouble();
        couponDiscountType = d['Type'] ?? 'FLAT';
        couponDescription = d['Description'] ?? '';
        couponExpiresAt = d['EndDate'] as Timestamp?;
      }

      // ── 2. Resolve target users ──────────────────────────────────────────
      List<String> userIds = [];
      List<String> fcmTokens = [];

      if (campaign.targetType == 'ALL') {
        final snap = await _db.collection('Users').get();
        for (final doc in snap.docs) {
          final data = doc.data();
          userIds.add(doc.id);
          final token = data['FcmToken'] as String?;
          if (token != null && token.isNotEmpty) fcmTokens.add(token);
        }
      } else if (campaign.targetType == 'SPECIFIC') {
        userIds = List<String>.from(campaign.targetUserIds);
        for (final uid in userIds) {
          final doc = await _db.collection('Users').doc(uid).get();
          if (doc.exists) {
            final token = doc.data()?['FcmToken'] as String?;
            if (token != null && token.isNotEmpty) fcmTokens.add(token);
          }
        }
      }

      if (userIds.isEmpty) {
        Get.snackbar(
          'No Users',
          'No target users found for this campaign.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // ── 3. Write UserCoupons docs directly (idempotent via set+merge) ────
      final now = Timestamp.now();
      const batchSize = 500; // Firestore batch limit
      for (int i = 0; i < userIds.length; i += batchSize) {
        final batch = _db.batch();
        final chunk = userIds.sublist(
          i,
          i + batchSize > userIds.length ? userIds.length : i + batchSize,
        );
        for (final uid in chunk) {
          // Deterministic doc ID — re-sending is idempotent
          final docId = '${campaign.couponId}_$uid';
          final ref = _db.collection('UserCoupons').doc(docId);
          batch.set(ref, {
            'UserId': uid,
            'CouponId': campaign.couponId,
            'CouponCode': campaign.couponCode,
            'CampaignId': campaign.id,
            'Status': 'PENDING',
            'AssignedAt': now,
            // Denormalized coupon fields — required for wallet display
            'DiscountValue': couponDiscountValue,
            'DiscountType': couponDiscountType,
            'Description': couponDescription,
            'ExpiresAt': couponExpiresAt,
            'RedeemedAt': null,
          }, SetOptions(merge: true));
        }
        await batch.commit();
      }

      // ── 4. Try FCM via FastAPI (optional — non-blocking) ─────────────────
      int fcmSent = 0;
      try {
        final payload = {
          'coupon_id': campaign.couponId,
          'coupon_code': campaign.couponCode,
          'campaign_id': campaign.id,
          'title': '🎁 New Offer for You!',
          'body':
              'Use code ${campaign.couponCode} to get a discount on your next order.',
          'user_ids': userIds,
          'user_tokens': fcmTokens,
        };
        final response = await http
            .post(
              Uri.parse('$_kApiBase/campaign/send'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body) as Map<String, dynamic>;
          fcmSent = result['fcm_sent'] ?? 0;
        }
      } catch (_) {
        // FastAPI unavailable — users will still see coupons via Firestore stream
      }

      // ── 5. Mark campaign ACTIVE in Firestore ─────────────────────────────
      await _db.collection('Campaigns').doc(campaign.id).update({
        'Status': 'ACTIVE',
        'SentAt': now,
        'TotalTargeted': userIds.length,
        'TotalSent': fcmSent,
        'UpdatedAt': now,
      });

      await fetchCampaigns();
      Get.snackbar(
        'Campaign Sent ✅',
        'Coupons delivered to ${userIds.length} users'
            '${fcmSent > 0 ? ' · $fcmSent push notifications sent' : ''}.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send campaign: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Analytics ─────────────────────────────────────────────────────────────
  // Computed directly from Firestore — no FastAPI dependency.

  Future<void> fetchAnalytics() async {
    try {
      // ── Redemptions: count + sum of DiscountAmount ─────────────────────
      final redemptionsAgg = await _db
          .collection('CouponRedemptions')
          .aggregate(count(), sum('DiscountAmount'))
          .get();
      totalRedemptions.value = redemptionsAgg.count ?? 0;
      totalDiscountGiven.value = (redemptionsAgg.getSum('DiscountAmount') ?? 0)
          .toDouble();

      // ── Acceptance rate: ACCEPTED+REDEEMED / all responded ────────────
      final respondedAgg = await _db
          .collection('UserCoupons')
          .where('Status', whereIn: ['ACCEPTED', 'DECLINED', 'REDEEMED'])
          .aggregate(count())
          .get();
      final acceptedAgg = await _db
          .collection('UserCoupons')
          .where('Status', whereIn: ['ACCEPTED', 'REDEEMED'])
          .aggregate(count())
          .get();

      final responded = respondedAgg.count ?? 0;
      final accepted = acceptedAgg.count ?? 0;
      final declined = responded - accepted;

      if (responded > 0) {
        acceptanceRate.value = (accepted / responded) * 100.0;
        declineRate.value = (declined / responded) * 100.0;
      } else {
        acceptanceRate.value = 0.0;
        declineRate.value = 0.0;
      }
    } catch (_) {
      // Non-critical — analytics silently unavailable (e.g. no internet)
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
