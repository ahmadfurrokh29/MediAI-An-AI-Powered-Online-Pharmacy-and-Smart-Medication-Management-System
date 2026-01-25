import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/icons/circular_icon.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MBottomAddToCart extends StatelessWidget {
  const MBottomAddToCart({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MCircularIcon(
                icon: Iconsax.minus,
                backgroundColor: MColors.darkGrey,
                width: 40,
                height: 40,
                color: MColors.white,
              ),
              const SizedBox(width: MSizes.spaceBtwItems),
              Text('2', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: MSizes.spaceBtwItems),
              MCircularIcon(
                icon: Iconsax.add,
                backgroundColor: MColors.black,
                width: 40,
                height: 40,
                color: MColors.white,
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
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
