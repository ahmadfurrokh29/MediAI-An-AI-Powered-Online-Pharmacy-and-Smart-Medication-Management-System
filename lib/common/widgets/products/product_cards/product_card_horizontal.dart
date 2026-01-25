import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/icons/circular_icon.dart';
import 'package:med/common/widgets/images/m_rounded_image.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';
import 'package:med/common/widgets/texts/product_price_text.dart';
import 'package:med/common/widgets/texts/product_title_text.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MProductCardHorizontal extends StatelessWidget {
  const MProductCardHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return Container(
      width: 310,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MSizes.productImageRadius),
        color: dark ? MColors.darkerGrey : MColors.light1,
      ),
      child: Row(
        children: [
          /// Thumbnail
          MRoundedContainer(
            height: 120,
            padding: EdgeInsets.all(MSizes.sm),
            backgroundColor: dark ? MColors.dark : MColors.light,
            child: Stack(
              children: [
                ///thumbnail image
                SizedBox(
                  height: 120,
                  width: 120,
                  child: MRoundedImage(
                    imageUrl: MImages.product1,
                    applyImageRadius: true,
                  ),
                ),

                /// sales tag
                Positioned(
                  top: 12,
                  child: MRoundedContainer(
                    radius: MSizes.sm,
                    backgroundColor: MColors.secondary.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: MSizes.sm,
                      vertical: MSizes.xs,
                    ),
                    child: Text(
                      '25%',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge!.apply(color: MColors.black),
                    ),
                  ),
                ),
                //Wishlist button
                Positioned(
                  top: 0,
                  right: 0,
                  child: MCircularIcon(icon: Iconsax.heart5, color: Colors.red),
                ),
              ],
            ),
          ),

          /// details
          SizedBox(
            width: 172,
            child: Padding(
              padding: EdgeInsets.only(top: MSizes.sm, left: MSizes.sm),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MProductTitleText(
                        title: 'Paracetamol 500mg Tablets',
                        smallSize: true,
                      ),
                      SizedBox(height: MSizes.spaceBtwItems / 2),
                      MBrandTitleTextWithVerifiedIcon(title: 'HealthCorp'),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ///Pricing
                      Flexible(child: MProductPriceText(price: '175')),

                      /// Add to cart button
                      Container(
                        decoration: const BoxDecoration(
                          color: MColors.dark,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(MSizes.cardRadiusMd),
                            bottomRight: Radius.circular(
                              MSizes.productImageRadius,
                            ),
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
          ),
        ],
      ),
    );
  }
}
