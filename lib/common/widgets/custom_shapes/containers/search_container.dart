import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/device/device_utility.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MSearchContainer extends StatelessWidget {
  const MSearchContainer({
    super.key,
    required this.text,
    this.icon = Iconsax.search_normal,
    this.showBackground = true,
    this.showBorder = true,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: MSizes.defaultSpace),
  });

  final String text;
  final IconData icon;
  final bool showBackground, showBorder;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Container(
          width: MDeviceUtils.getScreenWidth(context),
          padding: const EdgeInsets.all(MSizes.md),
          decoration: BoxDecoration(
            color: showBackground
                ? dark
                      ? MColors.dark
                      : MColors.light
                : Colors.transparent,
            borderRadius: BorderRadius.circular(MSizes.cardRadiusLg),
            border: showBorder ? Border.all(color: MColors.grey) : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: MColors.darkGrey),
              const SizedBox(width: MSizes.spaceBtwItems),
              Text(text, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
