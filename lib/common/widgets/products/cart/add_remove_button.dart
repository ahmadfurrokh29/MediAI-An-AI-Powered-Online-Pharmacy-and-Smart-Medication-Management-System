import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/icons/circular_icon.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MProductQuantityWithAddRemoveButton extends StatelessWidget {
  const MProductQuantityWithAddRemoveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ///add and remove buttons
        MCircularIcon(
          icon: Iconsax.minus,
          width: 32,
          height: 32,
          size: MSizes.md,
          color: MHelperFunctions.isDarkMode(context)
              ? MColors.white
              : MColors.black,
          backgroundColor: MHelperFunctions.isDarkMode(context)
              ? MColors.darkerGrey
              : MColors.light,
        ),
        const SizedBox(width: MSizes.spaceBtwItems),
        Text('2', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: MSizes.spaceBtwItems),
        MCircularIcon(
          icon: Iconsax.add,
          width: 32,
          height: 32,
          size: MSizes.md,
          color: MColors.white,
          backgroundColor: MColors.primary,
        ),
      ],
    );
  }
}
