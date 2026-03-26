import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/icons/circular_icon.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MBottomAddToCart extends StatelessWidget {
  const MBottomAddToCart({super.key, required this.productData});

  final Map<String, dynamic> productData;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final quantity = 1.obs;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MSizes.defaultSpace,
        vertical: MSizes.defaultSpace / 2,
      ),
      decoration: BoxDecoration(
        color: dark ? MColors.darkerGrey : MColors.light,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(MSizes.cardRadiusLg),
          topRight: Radius.circular(MSizes.cardRadiusLg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              MCircularIcon(
                icon: Iconsax.minus,
                backgroundColor: MColors.darkGrey,
                width: 40,
                height: 40,
                color: MColors.white,
                onPressed: () {
                  if (quantity.value > 1) quantity.value--;
                },
              ),
              const SizedBox(width: MSizes.spaceBtwItems),
              Obx(() => Text('${quantity.value}',
                  style: Theme.of(context).textTheme.titleSmall)),
              const SizedBox(width: MSizes.spaceBtwItems),
              MCircularIcon(
                icon: Iconsax.add,
                backgroundColor: MColors.black,
                width: 40,
                height: 40,
                color: MColors.white,
                onPressed: () => quantity.value++,
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              final cart = CartController.instance;
              cart.addToCart(productData, quantity: quantity.value);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(MSizes.md),
              backgroundColor: MColors.black,
              side: const BorderSide(color: MColors.black),
            ),
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}
