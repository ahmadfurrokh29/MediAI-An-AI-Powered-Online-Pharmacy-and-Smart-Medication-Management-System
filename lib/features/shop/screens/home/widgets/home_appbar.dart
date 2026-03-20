import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/products/wishlist/wishlist_menu_icon.dart';
import 'package:med/features/shop/controllers/home_controller.dart';
import 'package:med/utils/helpers/helper_functions.dart';
import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/products/cart/cart_menu_icon.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/constants/sizes.dart';

class MHomeAppbar extends StatelessWidget implements PreferredSizeWidget {
  const MHomeAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    // Req #1: get the HomeController (already registered by HomeScreen)
    final controller = Get.find<HomeController>();

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
          // Req #1: live user name from Firestore
          Obx(
            () => Text(
              controller.userName.value.isEmpty
                  ? 'Loading...'
                  : controller.userName.value,
              style: Theme.of(context).textTheme.headlineSmall!.apply(
                color: dark ? Colors.white : Colors.black,
              ),
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

  @override
  Size get preferredSize => const Size.fromHeight(MSizes.appBarHeight);
}
