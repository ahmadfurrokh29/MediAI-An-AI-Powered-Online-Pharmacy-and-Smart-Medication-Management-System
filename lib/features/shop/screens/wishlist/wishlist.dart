import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/icons/circular_icon.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:med/features/shop/controllers/wishlist_controller.dart';
import 'package:med/features/shop/screens/home/home.dart';
import 'package:med/utils/constants/sizes.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<WishlistController>();

    return Scaffold(
      appBar: MAppBar(
        showBackArrow: true,
        title: Text(
          'Wishlist',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          MCircularIcon(
            icon: Iconsax.add,
            onPressed: () => Get.to(const HomeScreen()),
          ),
        ],
      ), // MAppBar
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.wishlistProducts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No items in your wishlist yet.\nTap the ♡ on any product to save it.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(MSizes.defaultSpace),
            child: MGridLayout(
              itemCount: ctrl.wishlistProducts.length,
              itemBuilder: (_, index) => MProductCardVertical(
                productData: ctrl.wishlistProducts[index],
              ),
            ),
          ),
        );
      }),
    ); // Scaffold
  }
}
