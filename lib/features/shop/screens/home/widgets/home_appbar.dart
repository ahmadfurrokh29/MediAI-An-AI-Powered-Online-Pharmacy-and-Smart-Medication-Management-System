import 'package:flutter/material.dart';
import 'package:med/common/widgets/products/wishlist/wishlist_menu_icon.dart';
import 'package:med/utils/helpers/helper_functions.dart';
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
    final dark = MHelperFunctions.isDarkMode(context);
    return MAppBar(
      showBackArrow: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MTexts.homeAppbarTitle,
            style: Theme.of(context).textTheme.labelMedium!.apply(
              color: dark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            MTexts.homeAppbarSubTitle,
            style: Theme.of(context).textTheme.headlineSmall!.apply(
              color: dark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      actions: [
        MWishListIcon(
          onPressed: () {},
          iconColor: dark ? Colors.white : Colors.black,
        ),
        MCartCounterIcon(
          onPressed: () {},
          iconColor: dark ? Colors.white : Colors.black,
        ),
      ],
    );
  }

  // FIX 2: Add the required preferredSize getter.
  @override
  Size get preferredSize => const Size.fromHeight(MSizes.appBarHeight);
}
