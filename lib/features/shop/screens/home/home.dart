import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/custom_shapes/containers/search_container.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:med/common/widgets/products/search/product_search_sheet.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/shop/controllers/home_controller.dart';
import 'package:med/features/shop/screens/all_products/all_products.dart';
import 'package:med/features/shop/screens/home/widgets/home_appbar.dart';
import 'package:med/features/shop/screens/home/widgets/home_categories.dart';
import 'package:med/features/shop/screens/home/widgets/promo_slider.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Register HomeController once here; all child widgets reuse it via Get.find
    final controller = Get.put(HomeController());

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            MPrimaryHeaderContainer(
              child: Column(
                children: [
                  const SizedBox(height: MSizes.spaceBtwSections),
                  // Req #1: App bar shows live user name
                  const MHomeAppbar(),
                  const SizedBox(height: MSizes.spaceBtwSections),

                  // Req #2: Search bar — opens product search bottom sheet
                  GestureDetector(
                    onTap: () => openProductSearchSheet(context),
                    child: const MSearchContainer(text: 'Search in Store'),
                  ),

                  const SizedBox(height: MSizes.spaceBtwSections),
                  Padding(
                    padding: const EdgeInsets.only(left: MSizes.defaultSpace),
                    child: Column(
                      children: [
                        MSectionHeading(
                          title: 'Popular Categories',
                          showActionButton: false,
                          textColor: MColors.white,
                        ),
                        const SizedBox(height: MSizes.spaceBtwItems),
                        // Req #3: Only featured + active categories from Firestore
                        const MHomeCategories(),
                      ],
                    ),
                  ),
                  const SizedBox(height: MSizes.spaceBtwSections),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(MSizes.defaultSpace),
              child: Column(
                children: [
                  // Req #4: Active banners from Firestore 'Banners' collection
                  const MPromoSlider(),
                  const SizedBox(height: MSizes.spaceBtwItems),

                  // Req #5: Recommended products from Firestore (home shows top 4)
                  MSectionHeading(
                    title: 'Popular Products',
                    onPressed: () => Get.to(
                      () => AllProducts(
                        title: 'Popular Products',
                        products: controller.recommendedProducts.toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: MSizes.spaceBtwItems),

                  Obx(() {
                    final products = controller.recommendedProducts;

                    if (controller.isLoading.value && products.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (products.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No recommended products yet'),
                        ),
                      );
                    }

                    // Show only the first 4 on the home screen
                    final display = products.take(4).toList();
                    return MGridLayout(
                      itemCount: display.length,
                      itemBuilder: (_, index) =>
                          MProductCardVertical(productData: display[index]),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
