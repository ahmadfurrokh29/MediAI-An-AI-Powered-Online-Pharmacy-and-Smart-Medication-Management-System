import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/features/chatbot/chatbot_screen.dart';
import 'package:med/features/personalization/controllers/user_controller.dart';
import 'package:med/features/personalization/screens/settings/settings.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/features/shop/controllers/wishlist_controller.dart';
import 'package:med/features/shop/screens/home/home.dart';
import 'package:med/features/shop/screens/store/store.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final controller = Get.put(NavigationController());
    // Register WishlistController once so product cards anywhere can find it
    Get.put(WishlistController());
    // Register CartController once
    Get.put(CartController());
    // Register UserController once so profile/tile widgets can find it
    Get.put(UserController());
    return Scaffold(
      bottomNavigationBar: Obx(
        () => ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          child: NavigationBar(
            backgroundColor: dark ? MColors.dark : MColors.light,
            indicatorColor: MColors.primary.withValues(alpha: 0.3),
            height: 80,
            elevation: 50,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) =>
                controller.selectedIndex.value = index,
            destinations: [
              const NavigationDestination(
                icon: Icon(Iconsax.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Iconsax.shop),
                label: 'Store',
              ),
              const NavigationDestination(
                icon: Icon(Iconsax.message),
                label: 'Pharmacist',
              ),
              const NavigationDestination(
                icon: Icon(Iconsax.user),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const HomeScreen(),
    const Store(),
    const ChatbotScreen(),
    const SettingsScreen(),
  ];
}
