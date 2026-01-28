import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/shop/screens/product_details/widgets/bottom_add_to_cart_widget.dart';
import 'package:med/features/shop/screens/product_details/widgets/product_details_image_slider.dart';
import 'package:med/features/shop/screens/product_details/widgets/product_meta_data.dart';
import 'package:med/features/shop/screens/product_details/widgets/rating_share_widget.dart';
import 'package:med/features/shop/screens/product_reviews/product_reviews.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:readmore/readmore.dart';

class MProductDetail extends StatelessWidget {
  const MProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MBottomAddToCart(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 1 - Product Image Slider
            MProductImageSlider(),

            /// 2 - Product Details
            Padding(
              padding: const EdgeInsets.only(
                right: MSizes.defaultSpace,
                left: MSizes.defaultSpace,
                bottom: MSizes.defaultSpace,
              ),
              child: Column(
                children: [
                  /// --- Rating & Share Button
                  MRatingAndShare(),
                  MProductMetaData(),
                  SizedBox(height: MSizes.spaceBtwSections),

                  ///-checkout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle checkout action
                      },
                      child: Text('Checkout'),
                    ),
                  ),
                  SizedBox(height: MSizes.spaceBtwSections),

                  ///-Description
                  const MSectionHeading(
                    title: 'Description',
                    showActionButton: false,
                  ),
                  SizedBox(height: MSizes.spaceBtwItems),
                  ReadMoreText(
                    'This is a detailed description of the product. It provides all the necessary information that a customer might need before making a purchase decision. The description can include features, specifications, usage instructions, and any other relevant details that highlight the value of the product.',
                    trimLines: 3,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: ' Show more',
                    trimExpandedText: ' Show less',
                    moreStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    lessStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  ///- Reviews Section
                  const Divider(),
                  SizedBox(height: MSizes.spaceBtwItems),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const MSectionHeading(
                        title: 'Reviews(199)',
                        showActionButton: false,
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.arrow_right_3, size: 18),
                        onPressed: () =>
                            Get.to(() => const ProductReviewsScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
