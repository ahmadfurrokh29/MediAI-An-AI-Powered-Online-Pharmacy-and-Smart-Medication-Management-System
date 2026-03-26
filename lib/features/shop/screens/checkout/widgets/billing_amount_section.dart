import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/utils/constants/sizes.dart';

class MBillingAmountSection extends StatelessWidget {
  const MBillingAmountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    return Obx(() {
      return Column(
        children: [
          /// subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
              Text('Rs ${cart.subtotal.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: MSizes.spaceBtwItems / 2),

          /// shipping fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipping Fee', style: Theme.of(context).textTheme.bodyMedium),
              Text('Rs ${cart.shippingFee.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: MSizes.spaceBtwItems / 2),

          /// taxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax Fee (5%)', style: Theme.of(context).textTheme.bodyMedium),
              Text('Rs ${cart.taxFee.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: MSizes.spaceBtwItems / 2),

          /// total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Total', style: Theme.of(context).textTheme.bodyMedium),
              Text('Rs ${cart.totalAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      );
    });
  }
}
