import 'package:flutter/material.dart';
import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/products/cart/cart_menu_icon.dart';
// import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/constants/sizes.dart';

// FIX 1: Implement PreferredSizeWidget interface
class MHomeAppbar extends StatelessWidget implements PreferredSizeWidget { 
  const MHomeAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return MAppbar(
      showBackArrow: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MTexts.homeAppbarTitle,
            style: Theme.of(context)
                .textTheme
                .labelMedium!
                .apply(color: Colors.black),
          ),
          Text(
            MTexts.homeAppbarSubTitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .apply(color: Colors.black),
          ),
        ],
      ),
      actions: [
        MCartCounterIcon(
          onPressed: () {},
          iconColor: Colors.black,
        ),
      ],
    );
  }

  // FIX 2: Add the required preferredSize getter.
  @override
  Size get preferredSize => const Size.fromHeight(MSizes.appBarHeight);
}