import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/images/m_circular_image.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/shop/controllers/store_controller.dart';
import 'package:med/features/shop/screens/all_products/all_products.dart';
import 'package:med/features/shop/screens/brand/brand_products.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/enums.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MCategoryTab extends StatelessWidget {
  const MCategoryTab({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  /// Null → "View All" tab (global data).
  final String? categoryId;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final controller = StoreController.instance;

    // Category tabs: top 2 brands with products in that category, sorted by highest rated
    // View All tab: top 2 brands globally
    final List<Map<String, dynamic>> brands = categoryId != null
        ? controller.brandsForCategory(categoryId!, limit: 2)
        : controller.topBrandsGlobal(limit: 2);

    // Category tabs: show featured products for that category
    // View All tab: show top-rated products globally
    final List<Map<String, dynamic>> youMightLike = categoryId != null
        ? controller.featuredForCategory(categoryName!, limit: 4)
        : controller.topRatedGlobal(limit: 4);

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            children: [
              // ── Brand showcases ─────────────────────────────────────
              ...brands.map((brand) {
                final brandName = (brand['name'] ?? '').toString();
                final brandImage = (brand['image'] ?? '').toString().trim();
                final isNetwork = brandImage.startsWith('http');

                // In "View All" tab use overall product count;
                // in category tabs use category-filtered count.
                final int brandCount = categoryId == null
                    ? (brand['productCount'] ?? 0) as int
                    : controller.productCountForBrandInCategory(
                        brandName,
                        categoryName!,
                      );

                final products = controller.productsForBrand(
                  brandName,
                  limit: 3,
                  categoryName: categoryName,
                );

                return _brandShowcase(
                  context: context,
                  dark: dark,
                  brandName: brandName,
                  brandImage: brandImage,
                  isNetwork: isNetwork,
                  brandCount: brandCount,
                  products: products,
                );
              }),

              const SizedBox(height: MSizes.spaceBtwItems),

              // ── You might like ──────────────────────────────────────
              MSectionHeading(
                title: 'You might like',
                onPressed: () => Get.to(
                  () => AllProducts(
                    title: categoryName != null
                        ? 'Featured in $categoryName'
                        : 'Top Rated Products',
                    products: categoryId != null
                        ? controller.featuredForCategory(categoryName!)
                        : controller.topRatedGlobal(limit: 50),
                  ),
                ),
              ),
              const SizedBox(height: MSizes.spaceBtwItems),

              if (youMightLike.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No products found'),
                )
              else
                MGridLayout(
                  itemCount: youMightLike.length,
                  itemBuilder: (_, index) =>
                      MProductCardVertical(productData: youMightLike[index]),
                ),
              const SizedBox(height: MSizes.spaceBtwSections),
            ],
          ),
        ),
      ],
    );
  }

  Widget _brandShowcase({
    required BuildContext context,
    required bool dark,
    required String brandName,
    required String brandImage,
    required bool isNetwork,
    required int brandCount,
    required List<Map<String, dynamic>> products,
  }) {
    return GestureDetector(
      onTap: () => Get.to(
        () => BrandProducts(
          brandName: brandName,
          brandImage: brandImage,
          brandProductCount: brandCount,
          categoryName: categoryName,
        ),
      ),
      child: MRoundedContainer(
        showBorder: true,
        borderColor: MColors.darkGrey,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.all(MSizes.md),
        margin: const EdgeInsets.only(bottom: MSizes.spaceBtwItems),
        child: Column(
          children: [
            // Brand card header
            Row(
              children: [
                Flexible(
                  child: MCircularImage(
                    image: isNetwork ? brandImage : MImages.medIcon,
                    isNetworkImage: isNetwork,
                    backgroundColor: Colors.transparent,
                    height: 40,
                    width: 40,
                  ),
                ),
                const SizedBox(width: MSizes.spaceBtwItems / 2),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MBrandTitleTextWithVerifiedIcon(
                        title: brandName,
                        brandTextSize: TextSizes.large,
                      ),
                      Text(
                        '$brandCount Products',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: MSizes.spaceBtwItems),

            // Top 3 product images
            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No products yet'),
              )
            else
              Row(
                children: products.map((p) {
                  final img = (p['image'] ?? '').toString().trim();
                  final isNet = img.startsWith('http');
                  return Expanded(
                    child: MRoundedContainer(
                      height: 100,
                      padding: const EdgeInsets.all(MSizes.md),
                      margin: const EdgeInsets.only(right: MSizes.sm),
                      backgroundColor: dark
                          ? MColors.darkerGrey
                          : MColors.light,
                      child: isNet
                          ? Image.network(
                              img,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.medication),
                            )
                          : const Icon(Icons.medication, size: 40),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
