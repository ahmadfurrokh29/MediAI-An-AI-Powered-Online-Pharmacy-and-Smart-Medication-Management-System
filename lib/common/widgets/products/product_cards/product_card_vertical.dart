import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/styles/shadows.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/icons/circular_icon.dart';
import 'package:med/common/widgets/images/m_rounded_image.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';
import 'package:med/common/widgets/texts/product_price_text.dart';
import 'package:med/common/widgets/texts/product_title_text.dart';
import 'package:med/features/shop/screens/product_details/product_details.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MProductCardVertical extends StatelessWidget {
  const MProductCardVertical({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    //container with side padding, color, edge, radius and shadow
    return GestureDetector(
      onTap: ()=> Get.to(()=>const MProductDetail()),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          boxShadow: [MShadowStyle.verticalProductShadow],
          borderRadius: BorderRadius.circular(MSizes.productImageRadius),
          color: dark ? MColors.darkerGrey : MColors.white,
        ),
        child: Column(
          children: [
            //Thumbnail, Wishlist button, Discount badge
            MRoundedContainer(
              height: 180,
              padding: const EdgeInsets.all(MSizes.sm),
              backgroundColor: dark ? MColors.dark : MColors.light,
              child: Stack(
                children: [
                  //Thumbnail
                  const MRoundedImage(
                    imageUrl: MImages.product1,
                    applyImageRadius: true,
                  ),

                  //Wishlist button
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: MCircularIcon(
                      icon: Iconsax.heart5,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSizes.spaceBtwItems / 2),

            //Details
            Padding(
              padding: const EdgeInsets.only(left: MSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MProductTitleText(title: 'CBD medicine', smallSize: true),
                  const SizedBox(height: MSizes.spaceBtwItems / 2),
                  MBrandTitleTextWithVerifiedIcon(
                    title: 'Medlife',
                    textAlign: TextAlign.start,
                  ),

                  //price
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: MSizes.sm),
                  child: MProductPriceText(price: '9.99'),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: MColors.dark,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(MSizes.cardRadiusMd),
                      bottomRight: Radius.circular(MSizes.productImageRadius),
                    ),
                  ),
                  child: const SizedBox(
                    width: MSizes.iconLg * 1.2,
                    height: MSizes.iconLg * 1.2,
                    child: Center(
                      child: Icon(Iconsax.add5, color: MColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
