import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:med/features/shop/controllers/coupon_controller.dart';
import 'package:med/features/shop/models/user_coupon_model.dart';
import 'package:med/features/shop/screens/cart/cart.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class CouponWalletScreen extends StatelessWidget {
  const CouponWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final couponCtrl = Get.put(CouponController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Coupons',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          leading: const BackButton(),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Pending'),
              Tab(text: 'Used'),
            ],
          ),
        ),
        body: Obx(() {
          final active = couponCtrl.userCoupons
              .where((c) => c.isAccepted && !c.isExpired)
              .toList();
          final pending = couponCtrl.pendingCoupons;
          final used = couponCtrl.userCoupons
              .where((c) => c.isRedeemed || c.isExpired || c.isDeclined)
              .toList();

          return TabBarView(
            children: [
              _CouponList(coupons: active, type: 'active'),
              _CouponList(coupons: pending, type: 'pending'),
              _CouponList(coupons: used, type: 'used'),
            ],
          );
        }),
      ),
    );
  }
}

class _CouponList extends StatelessWidget {
  final List<UserCouponModel> coupons;
  final String type;

  const _CouponList({required this.coupons, required this.type});

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'pending'
                  ? 'No pending coupon offers'
                  : type == 'used'
                  ? 'No used coupons yet'
                  : 'No active coupons in wallet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: coupons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _CouponCard(uc: coupons[i], type: type),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final UserCouponModel uc;
  final String type;

  const _CouponCard({required this.uc, required this.type});

  @override
  Widget build(BuildContext context) {
    final couponCtrl = CouponController.instance;
    final dark = MHelperFunctions.isDarkMode(context);

    Color accentColor;
    IconData icon;
    switch (type) {
      case 'pending':
        accentColor = Colors.orange;
        icon = Icons.notifications_active;
        break;
      case 'used':
        accentColor = Colors.grey;
        icon = Icons.check_circle_outline;
        break;
      default:
        accentColor = MColors.primary;
        icon = Icons.local_offer;
    }

    return Container(
      decoration: BoxDecoration(
        color: dark ? MColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ── Left accent strip ──────────────────────────────────────────
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: accentColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          uc.couponCode,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: accentColor,
                          ),
                        ),
                        const Spacer(),
                        // Live discount badge — reads from Coupons collection,
                        // stays correct even if UserCoupon doc has stale DiscountValue = 0.
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              couponCtrl.liveDiscountLabelFor(uc),
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (uc.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        uc.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (uc.expiresAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expires: ${_formatDate(uc.expiresAt!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // ── Uses remaining (only shown for active multi-use coupons)
                    if (type == 'active') ...[
                      Obx(() {
                        final limit = couponCtrl.perUserLimitFor(uc);
                        if (limit <= 1) return const SizedBox.shrink();
                        final left = couponCtrl.usesLeftFor(uc);
                        final color = left <= 1
                            ? Colors.orange.shade600
                            : accentColor;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.replay_outlined,
                                size: 12,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$left of $limit uses remaining',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    // ── Accept / Decline for pending coupons ──────────────
                    if (type == 'pending') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => couponCtrl.acceptCoupon(uc),
                              child: const Text('Accept'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => couponCtrl.declineCoupon(uc),
                              child: const Text('Decline'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // ── "Use Now" shortcut for active coupons ─────────────
                    if (type == 'active') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Copy code button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentColor,
                              side: BorderSide(
                                color: accentColor.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.copy, size: 14),
                            label: Text(
                              uc.couponCode,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: uc.couponCode),
                              );
                              Get.snackbar(
                                'Copied!',
                                '"${uc.couponCode}" copied to clipboard.',
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Navigate to cart with code pre-filled
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.shopping_cart, size: 14),
                            label: const Text(
                              'Use Now',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              // Pre-fill the coupon code so it's ready at cart
                              couponCtrl.couponCodeController.text =
                                  uc.couponCode;
                              Get.to(() => const CartScreen());
                            },
                          ),
                        ],
                      ),
                    ],
                    // ── Status chip for used coupons ───────────────────────
                    if (type == 'used') ...[
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          uc.status,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: uc.isRedeemed
                            ? Colors.purple
                            : uc.isDeclined
                            ? Colors.red
                            : Colors.grey,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // ── Dashed separator ───────────────────────────────────────────
            _DashedVerticalDivider(color: accentColor.withValues(alpha: 0.3)),
            // ── Right icon area ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                icon,
                size: 32,
                color: accentColor.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _DashedVerticalDivider extends StatelessWidget {
  final Color color;
  const _DashedVerticalDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(1, double.infinity),
      painter: _DashedLinePainter(color: color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    double y = 0;
    const dashHeight = 6;
    const dashSpace = 4;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
