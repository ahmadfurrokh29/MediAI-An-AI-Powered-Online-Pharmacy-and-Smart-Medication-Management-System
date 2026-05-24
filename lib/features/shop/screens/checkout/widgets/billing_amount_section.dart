import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/features/shop/controllers/coupon_controller.dart';
import 'package:med/utils/constants/sizes.dart';

class MBillingAmountSection extends StatelessWidget {
  const MBillingAmountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final couponCtrl = Get.find<CouponController>();
    return Obx(() {
      final discount = couponCtrl.discountAmount.value;
      final total = cart.subtotal + cart.shippingFee + cart.taxFee - discount;
      return Column(
        children: [
          /// subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'Rs ${cart.subtotal.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: MSizes.spaceBtwItems / 2),

          /// shipping fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Fee',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Rs ${cart.shippingFee.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: MSizes.spaceBtwItems / 2),

          /// taxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax Fee (5%)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Rs ${cart.taxFee.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),

          /// coupon discount row (visible only when applied)
          if (discount > 0) ...[
            const SizedBox(height: MSizes.spaceBtwItems / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Coupon (${couponCtrl.appliedCoupon.value?.code ?? ''})',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.green),
                    ),
                  ],
                ),
                Text(
                  '- Rs ${discount.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.green),
                ),
              ],
            ),
          ],

          const SizedBox(height: MSizes.spaceBtwItems / 2),

          /// total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Total',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Rs ${total.clamp(0, double.infinity).toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      );
    });
  }
}
