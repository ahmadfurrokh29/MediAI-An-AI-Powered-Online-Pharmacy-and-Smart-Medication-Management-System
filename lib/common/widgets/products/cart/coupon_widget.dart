import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/features/shop/controllers/coupon_controller.dart';
import 'package:med/features/shop/models/user_coupon_model.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MCouponCode extends StatelessWidget {
  const MCouponCode({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final couponCtrl = Get.put(CouponController());
    final cart = CartController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Manual Code Entry ──────────────────────────────────────────────
        MRoundedContainer(
          showBorder: true,
          backgroundColor: dark ? MColors.dark : MColors.white,
          padding: EdgeInsets.only(
            top: MSizes.sm,
            bottom: MSizes.sm,
            left: MSizes.md,
            right: MSizes.sm,
          ),
          child: Row(
            children: [
              Flexible(
                child: TextFormField(
                  controller: couponCtrl.couponCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Enter Promo Code To Get Discount',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              Obx(
                () => SizedBox(
                  width: 80,
                  child: couponCtrl.isApplying.value
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : couponCtrl.hasCouponApplied
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          onPressed: couponCtrl.removeCoupon,
                          child: const Text('Remove'),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: dark
                                ? MColors.white.withValues(alpha: 0.5)
                                : MColors.dark.withValues(alpha: 0.5),
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                          ),
                          onPressed: () => couponCtrl.applyFromTextField(
                            subtotal: cart.subtotal,
                            shippingFee: cart.shippingFee,
                            taxFee: cart.taxFee,
                          ),
                          child: const Text('Apply'),
                        ),
                ),
              ),
            ],
          ),
        ),

        // ── Validation Feedback ────────────────────────────────────────────
        Obx(() {
          if (couponCtrl.couponError.value.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                couponCtrl.couponError.value,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            );
          }
          if (couponCtrl.couponSuccess.value.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    couponCtrl.couponSuccess.value,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // ── Wallet Coupons Selector ────────────────────────────────────────
        Obx(() {
          final wallet = couponCtrl.walletCoupons;
          if (wallet.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Your Coupons',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: wallet.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) =>
                      _WalletCouponChip(userCoupon: wallet[i]),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _WalletCouponChip extends StatelessWidget {
  final UserCouponModel userCoupon;
  const _WalletCouponChip({required this.userCoupon});

  @override
  Widget build(BuildContext context) {
    final couponCtrl = CouponController.instance;
    final cart = CartController.instance;

    // Wrap in Obx so the chip re-renders when:
    //  (a) the applied coupon changes (selected state)
    //  (b) _liveDiscounts is populated after async fetch
    return Obx(() {
      final isSelected =
          couponCtrl.appliedCoupon.value?.code.toUpperCase() ==
          userCoupon.couponCode.toUpperCase();

      // Use live discount fetched from Coupons collection; fall back to stored value.
      final discountLabel = couponCtrl.liveDiscountLabelFor(userCoupon);

      return GestureDetector(
        onTap: () {
          if (isSelected) {
            couponCtrl.removeCoupon();
          } else {
            couponCtrl.applyCouponFromWallet(
              userCoupon: userCoupon,
              subtotal: cart.subtotal,
              shippingFee: cart.shippingFee,
              taxFee: cart.taxFee,
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer,
                    size: 14,
                    color: isSelected ? Colors.green : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userCoupon.couponCode,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? Colors.green : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                discountLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.green.shade700
                      : Colors.teal.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
