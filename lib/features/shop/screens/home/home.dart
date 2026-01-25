import 'package:flutter/material.dart';
import 'package:med/common/widgets/custom_shapes/containers/search_container.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/shop/screens/home/widgets/home_appbar.dart';
import 'package:med/features/shop/screens/home/widgets/home_categories.dart';
import 'package:med/features/shop/screens/home/widgets/promo_slider.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          MPrimaryHeaderContainer(
            child: Column(
              children: [
                const SizedBox(height: MSizes.spaceBtwSections),
                MHomeAppbar(),
                const SizedBox(height: MSizes.spaceBtwSections),
                MSearchContainer(text: 'Search in Store'),
                const SizedBox(height: MSizes.spaceBtwSections),
                Padding(
                  padding: const EdgeInsets.only(left: MSizes.defaultSpace),
                  child: Column(
                    children: [
                      //Heading After Search bar
                      MSectionHeading(
                        title: 'Popular Categories',
                        showActionButton: false,
                        textColor: MColors.white,
                      ),
                      const SizedBox(height: MSizes.spaceBtwItems),

                      //Horizontal Scrollable catagories
                      MHomeCategories(),
                    ],
                  ),
                ),
                SizedBox(height: MSizes.spaceBtwSections),
              ],
            ),
          ),
          //body carousel
          Padding(
            padding: const EdgeInsets.all(MSizes.defaultSpace),
            child: Column(
              children: [
                const MPromoSlider(
                  banners: [
                    MImages.promoBanner2,
                    MImages.promoBanner2,
                    MImages.promoBanner2,
                  ],
                ),
                const SizedBox(height: MSizes.spaceBtwItems),
                MSectionHeading(title: 'Popular Products', onPressed: () {}),
                const SizedBox(height: MSizes.spaceBtwItems),
                //Added a grid view for products
                MGridLayout(
                  itemCount: 4,
                  itemBuilder: (_, index) => const MProductCardVertical(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
