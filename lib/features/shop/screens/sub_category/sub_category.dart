import 'package:flutter/material.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/images/m_rounded_image.dart';
import 'package:med/common/widgets/products/product_cards/product_card_horizontal.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';

class SubCategoriesScreen extends StatelessWidget {
  const SubCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MAppBar(title: Text('Medicine'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            children: [
              ///--Banner
              MRoundedImage(
                imageUrl: MImages.promoBanner3,
                width: double.infinity,
                applyImageRadius: true,
              ),
              SizedBox(height: MSizes.spaceBtwSections),

              ///--Sub Categories
              Column(
                children: [
                  /// Heading
                  MSectionHeading(title: 'Pain-killers', onPressed: () {}),
                  SizedBox(height: MSizes.spaceBtwItems / 2),

                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      itemCount: 4,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: MSizes.spaceBtwItems),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) =>
                          const MProductCardHorizontal(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
