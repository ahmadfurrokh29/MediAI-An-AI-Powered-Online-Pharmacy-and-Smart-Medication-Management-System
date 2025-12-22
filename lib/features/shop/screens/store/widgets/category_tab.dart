


import 'package:flutter/material.dart';
import 'package:med/common/widgets/brands/brand_show_case.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';

class MCategoryTab extends StatelessWidget {
  const MCategoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            children: [
              /// -- Brands
              const MBrandShowcase(images: [MImages.product2, MImages.product3, MImages.product4]),
              const MBrandShowcase(images: [MImages.product5, MImages.product6, MImages.product7]),
              const SizedBox(height: MSizes.spaceBtwItems),

              /// -- Products
              MSectionHeading(title: 'You might like', onPressed: () {}),
              const SizedBox(height: MSizes.spaceBtwItems),

              MGridLayout(itemCount: 4, itemBuilder: (_, index) => const MProductCardVertical()),
              const SizedBox(height: MSizes.spaceBtwSections),
            ],
          ), // Column
        ), // Padding 
      ],
    ); // ListView
  }
}