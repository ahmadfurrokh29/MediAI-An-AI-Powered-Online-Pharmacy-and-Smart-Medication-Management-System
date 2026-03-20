import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/custom_shapes/containers/search_container.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/product_cards/product_card_vertical.dart';
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
                    onTap: () => _openSearchSheet(context, controller),
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

                  // Req #5: Recommended products from Firestore
                  MSectionHeading(
                    title: 'Popular Products',
                    onPressed: () => Get.to(() => const AllProducts()),
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

                    return MGridLayout(
                      itemCount: products.length,
                      itemBuilder: (_, index) =>
                          MProductCardVertical(productData: products[index]),
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

  // Req #2: bottom sheet with live search across all products
  void _openSearchSheet(BuildContext context, HomeController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                children: [
                  // Search field
                  TextField(
                    autofocus: true,
                    onChanged: controller.searchProducts,
                    decoration: InputDecoration(
                      hintText: 'Search products, brands, categories…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          controller.searchResults.clear();
                          Navigator.pop(ctx);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Results
                  Expanded(
                    child: Obx(() {
                      if (controller.isSearching.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (controller.searchResults.isEmpty) {
                        return const Center(
                          child: Text('Start typing to search…'),
                        );
                      }
                      return ListView.separated(
                        controller: scrollCtrl,
                        itemCount: controller.searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = controller.searchResults[i];
                          final image = (p['image'] ?? '').toString();
                          final isNetwork = image.startsWith('http');
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isNetwork
                                  ? Image.network(
                                      image,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.medication, size: 40),
                            ),
                            title: Text((p['name'] ?? '').toString()),
                            subtitle: Text(
                              '${p['brandName'] ?? ''} • ${p['categoryName'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              'Rs ${(p['price'] ?? 0).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
