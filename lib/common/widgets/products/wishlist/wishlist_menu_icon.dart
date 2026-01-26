import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/features/shop/screens/wishlist/wishlist.dart';

class MWishListIcon extends StatelessWidget {
  const MWishListIcon({
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
          onPressed: () => Get.to(() => const FavouriteScreen()),
          icon: Icon(Iconsax.heart, color: iconColor),
        ),
        /*Positioned(
          right: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: MColors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Text(
                '2',
                style: Theme.of(context).textTheme.labelLarge!.apply(
                  color: MColors.white,
                  fontSizeFactor: 1.0,
                ),
              ),
            ),
          ),
        ),*/
      ],
    );
  }
}
