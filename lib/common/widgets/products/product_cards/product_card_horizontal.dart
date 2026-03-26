import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
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

// Fallback image pool — same pool used by the vertical card
const _kHorizontalFallbacks = [
  MImages.product1,
  MImages.product2,
  MImages.product3,
  MImages.product4,
  MImages.product5,
  MImages.product6,
  MImages.product7,
  MImages.product8,
  MImages.product9,
  MImages.product10,
];

class MProductCardHorizontal extends StatelessWidget {
  const MProductCardHorizontal({super.key, this.productData});

  /// Optional live product data from Firestore.
  /// Keys: id, name, brandName, price, salePrice, image
  final Map<String, dynamic>? productData;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);

    // ── Resolve display values ─────────────────────────────────────────────
    final String imageUrl = (productData?['image'] ?? '').toString().trim();
    final bool isNetwork =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    final int fallbackIndex =
        (productData?['name'] ?? '').toString().hashCode.abs() %
        _kHorizontalFallbacks.length;
    final String displayImage = isNetwork
        ? imageUrl
        : _kHorizontalFallbacks[fallbackIndex];

    final String productName = (productData?['name'] ?? 'CBD medicine')
        .toString();
    final String brandName = (productData?['brandName'] ?? 'Medlife')
        .toString();

    final double salePrice = (productData?['salePrice'] ?? 0).toDouble();
    final double price = (productData?['price'] ?? 175).toDouble();
    final String displayPrice = (salePrice > 0 ? salePrice : price)
        .toStringAsFixed(0);

    int discountPercent = 0;
    if (salePrice > 0 && price > 0 && salePrice < price) {
      discountPercent = (((price - salePrice) / price) * 100).round();
    }
    // ──────────────────────────────────────────────────────────────────────

    return GestureDetector(
      onTap: () => Get.to(() => MProductDetail(productData: productData)),
      child: Container(
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
                      imageUrl: displayImage,
                      applyImageRadius: true,
                      isNetworkImage: isNetwork,
                    ),
                  ),

                  /// sales tag — only when there is a real discount
                  if (discountPercent > 0)
                    Positioned(
                      top: 12,
                      child: MRoundedContainer(
                        radius: MSizes.sm,
                        backgroundColor: MColors.secondary.withValues(
                          alpha: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: MSizes.sm,
                          vertical: MSizes.xs,
                        ),
                        child: Text(
                          '$discountPercent%',
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
                    child: MCircularIcon(
                      icon: Iconsax.heart5,
                      color: Colors.red,
                    ),
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
                        MProductTitleText(title: productName, smallSize: true),
                        SizedBox(height: MSizes.spaceBtwItems / 2),
                        MBrandTitleTextWithVerifiedIcon(title: brandName),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ///Pricing
                        Flexible(child: MProductPriceText(price: displayPrice)),

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
      ),
    );
  }
}
