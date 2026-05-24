import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/shop/controllers/coupon_controller.dart';

/// Handles all incoming FCM push notifications related to coupon offers.
///
/// Lifecycle:
///   - App in foreground  → show in-app [AlertDialog] with Accept/Decline.
///   - App opened via tap on background/terminated notification → same dialog.
///
/// Integration:
///   Call [FCMNotificationService.init()] once from [main.dart] after
///   Firebase.initializeApp().
class FCMNotificationService {
  FCMNotificationService._();

  /// Call once at startup, after Firebase.initializeApp().
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS / macOS / Web)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Save FCM token to Firestore for the current user
    await _saveTokenToFirestore();

    // Refresh token whenever it rotates
    messaging.onTokenRefresh.listen(_updateTokenInFirestore);

    // Listen while app is in the foreground
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // App was opened from a background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // App was TERMINATED and opened via notification
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      // Delay slightly so the widget tree is ready
      Future.delayed(const Duration(seconds: 1), () => _handleMessage(initial));
    }
  }

  // ── FCM token persistence ──────────────────────────────────────────────────
  static Future<void> _saveTokenToFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'FcmToken': token,
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-critical — token will be saved on next login
    }
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'FcmToken': token,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ── Internal handler ───────────────────────────────────────────────────────
  static void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';

    if (type == 'COUPON_OFFER') {
      _showCouponOfferDialog(
        couponId: data['coupon_id'] ?? '',
        couponCode: data['coupon_code'] ?? '',
        campaignId: data['campaign_id'] ?? '',
        title: message.notification?.title ?? 'New Coupon Offer!',
        body: message.notification?.body ?? 'You have a new coupon waiting.',
      );
    }
  }

  // ── Accept / Decline Dialog ────────────────────────────────────────────────
  static void _showCouponOfferDialog({
    required String couponId,
    required String couponCode,
    required String campaignId,
    required String title,
    required String body,
  }) {
    // Don't show if already showing (prevents stacking)
    if (Get.isDialogOpen ?? false) return;

    Get.dialog(
      _CouponOfferDialog(
        couponId: couponId,
        couponCode: couponCode,
        campaignId: campaignId,
        title: title,
        body: body,
      ),
      barrierDismissible: false,
    );
  }
}

/// In-app dialog shown when a COUPON_OFFER FCM notification arrives.
class _CouponOfferDialog extends StatefulWidget {
  final String couponId;
  final String couponCode;
  final String campaignId;
  final String title;
  final String body;

  const _CouponOfferDialog({
    required this.couponId,
    required this.couponCode,
    required this.campaignId,
    required this.title,
    required this.body,
  });

  @override
  State<_CouponOfferDialog> createState() => _CouponOfferDialogState();
}

class _CouponOfferDialogState extends State<_CouponOfferDialog> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      // Find the pending UserCoupon from the controller
      final ctrl = Get.find<CouponController>();
      final uc = ctrl.userCoupons.firstWhereOrNull(
        (u) => u.couponId == widget.couponId && u.status == 'PENDING',
      );
      if (uc != null) {
        await ctrl.acceptCoupon(uc);
        Get.back();
        Get.snackbar(
          'Coupon Accepted! 🎉',
          'Use code ${widget.couponCode} at checkout.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF38A169),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        // UserCoupons stream may not have loaded yet — wait briefly
        await Future.delayed(const Duration(milliseconds: 800));
        final uc2 = ctrl.userCoupons.firstWhereOrNull(
          (u) => u.couponId == widget.couponId && u.status == 'PENDING',
        );
        if (uc2 != null) {
          await ctrl.acceptCoupon(uc2);
          Get.back();
          Get.snackbar(
            'Coupon Accepted! 🎉',
            'Use code ${widget.couponCode} at checkout.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF38A169),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } else {
          Get.back();
          Get.snackbar(
            'Notice',
            'Coupon already processed.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Could not accept coupon. Try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _decline() async {
    setState(() => _loading = true);
    try {
      final ctrl = Get.find<CouponController>();
      final uc = ctrl.userCoupons.firstWhereOrNull(
        (u) => u.couponId == widget.couponId && u.status == 'PENDING',
      );
      if (uc != null) {
        await ctrl.declineCoupon(uc);
      }
      Get.back();
      Get.snackbar(
        'Offer Declined',
        'You can always find coupons in your wallet.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gradient header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4299E1), Color(0xFF667EEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.body,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Coupon code badge ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF90CDF4),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR COUPON CODE',
                    style: TextStyle(
                      color: Color(0xFF4A5568),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.couponCode,
                    style: const TextStyle(
                      color: Color(0xFF2B6CB0),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: _loading
                ? const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Row(
                    children: [
                      // Decline
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _decline,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFE53E3E)),
                            foregroundColor: const Color(0xFFE53E3E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Accept
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _accept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38A169),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Accept Offer 🎉',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
