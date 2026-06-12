import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med/features/shop/models/coupon_model.dart';
import 'package:med/features/shop/models/user_coupon_model.dart';

/// Firestore CRUD layer for coupons.
/// FastAPI is called through CouponApiService — this class handles only
/// direct Firestore read/write operations.
class CouponRepository {
  static CouponRepository get instance => CouponRepository._();
  CouponRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ── Fetch coupon by code ──────────────────────────────────────────────────

  Future<CouponModel?> fetchCouponByCode(String code) async {
    final snap = await _db
        .collection('Coupons')
        .where('Code', isEqualTo: code.toUpperCase().trim())
        .where('IsActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return CouponModel.fromSnapshot(snap.docs.first);
  }

  // ── Fetch all accepted user coupons ───────────────────────────────────────

  Future<List<UserCouponModel>> fetchAcceptedUserCoupons() async {
    if (_uid.isEmpty) return [];
    final snap = await _db
        .collection('UserCoupons')
        .where('UserId', isEqualTo: _uid)
        .where('Status', isEqualTo: 'ACCEPTED')
        .get();
    return snap.docs.map((d) => UserCouponModel.fromSnapshot(d)).toList();
  }

  /// Stream for real-time updates — used by the coupon wallet screen.
  Stream<List<UserCouponModel>> streamUserCoupons() {
    if (_uid.isEmpty) return const Stream.empty();
    return _db
        .collection('UserCoupons')
        .where('UserId', isEqualTo: _uid)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserCouponModel.fromSnapshot(d)).toList(),
        );
  }

  // ── Fetch pending (unread) user coupons ────────────────────────────────────

  Stream<List<UserCouponModel>> streamPendingUserCoupons() {
    if (_uid.isEmpty) return const Stream.empty();
    return _db
        .collection('UserCoupons')
        .where('UserId', isEqualTo: _uid)
        .where('Status', isEqualTo: 'PENDING')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserCouponModel.fromSnapshot(d)).toList(),
        );
  }

  // ── Accept coupon (Firestore write) ───────────────────────────────────────

  Future<void> acceptUserCoupon(String userCouponId) async {
    await _db.collection('UserCoupons').doc(userCouponId).update({
      'Status': 'ACCEPTED',
      'AcceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Decline coupon (Firestore write) ──────────────────────────────────────

  Future<void> declineUserCoupon(String userCouponId) async {
    await _db.collection('UserCoupons').doc(userCouponId).update({
      'Status': 'DECLINED',
      'DeclinedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Count how many times user redeemed a coupon ───────────────────────────

  Future<int> getUserRedemptionCount(String couponId) async {
    if (_uid.isEmpty) return 0;
    final snap = await _db
        .collection('CouponRedemptions')
        .where('UserId', isEqualTo: _uid)
        .where('CouponId', isEqualTo: couponId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ── Record redemption ─────────────────────────────────────────────────────

  Future<void> recordRedemption({
    required String couponId,
    required String couponCode,
    required String orderId,
    required double discountAmount,
  }) async {
    final batch = _db.batch();

    // 1. Write CouponRedemptions record
    final redemptionRef = _db.collection('CouponRedemptions').doc();
    batch.set(redemptionRef, {
      'UserId': _uid,
      'CouponId': couponId,
      'CouponCode': couponCode,
      'OrderId': orderId,
      'DiscountAmount': discountAmount,
      'RedeemedAt': FieldValue.serverTimestamp(),
    });

    // 2. Increment global usage count on the Coupon doc
    final couponRef = _db.collection('Coupons').doc(couponId);
    batch.update(couponRef, {
      'UsageCount': FieldValue.increment(1),
      'UpdatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ── Mark a UserCoupon doc as REDEEMED ─────────────────────────────────────

  Future<void> redeemUserCoupon(String userCouponId) async {
    await _db.collection('UserCoupons').doc(userCouponId).update({
      'Status': 'REDEEMED',
      'RedeemedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Mark a UserCoupon doc as EXPIRED ──────────────────────────────────────

  Future<void> expireUserCoupon(String userCouponId) async {
    await _db.collection('UserCoupons').doc(userCouponId).update({
      'Status': 'EXPIRED',
      'ExpiredAt': FieldValue.serverTimestamp(),
    });
  }
}
