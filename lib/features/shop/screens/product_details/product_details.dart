import 'package:flutter/material.dart';
import 'package:med/features/shop/screens/product_details/widgets/product_details_image_slider.dart';
import 'package:med/features/shop/screens/product_details/widgets/product_meta_data.dart';
import 'package:med/features/shop/screens/product_details/widgets/rating_share_widget.dart';
import 'package:med/utils/constants/sizes.dart';


class MProductDetail extends StatelessWidget {
  const MProductDetail({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

