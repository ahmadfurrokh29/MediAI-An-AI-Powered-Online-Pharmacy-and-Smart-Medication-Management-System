import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/features/shop/screens/cart/cart.dart';

import '../../../../utils/constants/colors.dart';

class MCartCounterIcon extends StatelessWidget {
  const MCartCounterIcon({
    super.key,
    required this.onPressed,
    required this.iconColor,
  });

  final VoidCallback onPressed;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: () => Get.to(() => const CartScreen()),
          icon: Icon(Iconsax.shopping_bag, color: iconColor),
        ),
        Positioned(
          right: 0,
          child: Obx(() {
            final count = CartController.instance.totalItems;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: MColors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelLarge!.apply(
                    color: MColors.white,
                    fontSizeFactor: 1.0,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
