import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/appbar/tabbar.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/custom_shapes/containers/search_container.dart';
import 'package:med/common/widgets/images/m_circular_image.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/cart/cart_menu_icon.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/shop/controllers/store_controller.dart';
import 'package:med/features/shop/screens/brand/all_brands.dart';
import 'package:med/features/shop/screens/brand/brand_products.dart';
import 'package:med/features/shop/screens/store/widgets/category_tab.dart';
import 'package:med/features/shop/screens/store/widgets/store_search_sheet.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/enums.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class Store extends StatelessWidget {
  const Store({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final controller = Get.put(StoreController());

    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          appBar: MAppBar(
            title: Text(
              'Store',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      // Build tab list: "View All" + one per active category
      final cats = controller.categories;
      final tabCount = cats.length + 1;

      return DefaultTabController(
        length: tabCount,
        child: Scaffold(
          appBar: MAppBar(
            title: Text(
              'Store',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            actions: [
              MCartCounterIcon(
                onPressed: () {},
                iconColor: dark ? Colors.white : Colors.black,
              ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  floating: true,
                  backgroundColor: dark ? Colors.black : Colors.white,
                  expandedHeight: 440,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.all(MSizes.defaultSpace),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: MSizes.spaceBtwItems),
                        // Search — searches both products & brands
                        Builder(
                          builder: (ctx) => MSearchContainer(
                            text: 'Search in store',
                            showBorder: true,
                            showBackground: false,
                            padding: EdgeInsets.zero,
                            onTap: () => openStoreSearchSheet(ctx),
                          ),
                        ),
                        const SizedBox(height: MSizes.spaceBtwSections),

                        // ── Featured Brands ───────────────────────────
                        MSectionHeading(
                          title: 'Featured Brands',
                          onPressed: () =>
                              Get.to(() => const AllBrandsScreen()),
                        ),
                        const SizedBox(height: MSizes.spaceBtwItems / 1.5),
                        _buildFeaturedBrands(controller, dark),
                      ],
                    ),
                  ),
                  // Dynamic tabs
                  bottom: MTabBar(
                    tabs: [
                      const Tab(child: Text('View All')),
                      ...cats.map(
                        (c) => Tab(child: Text((c['name'] as String))),
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                // "View All" tab — global top brands & products
                MCategoryTab(categoryId: null, categoryName: null),
                // One tab per category
                ...cats.map(
                  (c) => MCategoryTab(
                    categoryId: c['id'] as String,
                    categoryName: c['name'] as String,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Builds the featured brands grid from Firestore data.
  Widget _buildFeaturedBrands(StoreController controller, bool dark) {
    final brands = controller.featuredBrands;
    if (brands.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No featured brands yet'),
      );
    }

    return MGridLayout(
      itemCount: brands.length > 4 ? 4 : brands.length,
      mainAxisExtent: 80,
      itemBuilder: (context, index) {
        final brand = brands[index];
        final imageUrl = (brand['image'] ?? '').toString().trim();
        final isNetwork =
            imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
        final name = (brand['name'] ?? '').toString();
        final count = brand['productCount'] ?? 0;

        return GestureDetector(
          onTap: () => Get.to(
            () => BrandProducts(
              brandName: name,
              brandImage: imageUrl,
              brandProductCount: count,
            ),
          ),
          child: MRoundedContainer(
            showBorder: true,
            backgroundColor: dark ? Colors.transparent : MColors.lightGrey,
            padding: const EdgeInsets.all(MSizes.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: MCircularImage(
                    image: isNetwork ? imageUrl : MImages.medIcon,
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
                        title: name,
                        brandTextSize: TextSizes.large,
                      ),
                      Text(
                        '$count Products',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
