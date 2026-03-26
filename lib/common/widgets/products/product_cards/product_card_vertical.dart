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
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/features/shop/controllers/wishlist_controller.dart';
import 'package:med/features/shop/screens/product_details/product_details.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

// Pool of local product images used as per-product varied fallback
const _kProductFallbacks = [
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

class MProductCardVertical extends StatelessWidget {
  const MProductCardVertical({super.key, this.productData});

  /// Optional live product data from Firestore.
  /// Keys: id, name, brandName, price, salePrice, image
  final Map<String, dynamic>? productData;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);

    // Resolve display values: use backend data when available, fallback to defaults
    final String imageUrl = (productData?['image'] ?? '').toString().trim();
    final bool isNetwork =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    // Use a varied local fallback based on the product name hash so every
    // product card shows a different placeholder image.
    final int fallbackIndex =
        (productData?['name'] ?? '').toString().hashCode.abs() %
        _kProductFallbacks.length;
    final String displayImage = isNetwork
        ? imageUrl
        : _kProductFallbacks[fallbackIndex];

    final String productName = (productData?['name'] ?? 'CBD medicine')
        .toString();
    final String brandName = (productData?['brandName'] ?? 'Medlife')
        .toString();

    // Show sale price if > 0, else show regular price
    final double salePrice = (productData?['salePrice'] ?? 0).toDouble();
    final double price = (productData?['price'] ?? 175).toDouble();
    final String displayPrice = (salePrice > 0 ? salePrice : price)
        .toStringAsFixed(0);

    // Discount badge: only shown when salePrice < price and both > 0
    int discountPercent = 0;
    if (salePrice > 0 && price > 0 && salePrice < price) {
      discountPercent = (((price - salePrice) / price) * 100).round();
    }

    return GestureDetector(
      onTap: () => Get.to(() => MProductDetail(productData: productData)),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          boxShadow: [MShadowStyle.verticalProductShadow],
          borderRadius: BorderRadius.circular(MSizes.productImageRadius),
          color: dark ? MColors.darkerGrey : MColors.light1,
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
                  MRoundedImage(
                    imageUrl: displayImage,
                    applyImageRadius: true,
                    isNetworkImage: isNetwork,
                  ),

                  /// sales tag — only shown when there is a real discount
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
                    child: _WishlistButton(
                      productId: (productData?['id'] ?? '').toString(),
                      productData: productData,
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
                  MProductTitleText(title: productName, smallSize: true),
                  const SizedBox(height: MSizes.spaceBtwItems / 2),
                  MBrandTitleTextWithVerifiedIcon(
                    title: brandName,
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: MSizes.sm),
                  child: MProductPriceText(price: displayPrice),
                ),

                ///add to cart button
                GestureDetector(
                  onTap: () {
                    if (productData != null) {
                      CartController.instance.addToCart(productData!);
                    }
                  },
                  child: Container(
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wishlist toggle button ─────────────────────────────────────────────────
// Separated into its own StatelessWidget so the Obx re-render only
// rebuilds this small widget, not the entire card.
class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.productId, required this.productData});

  final String productId;
  final Map<String, dynamic>? productData;

  @override
  Widget build(BuildContext context) {
    // Lazily find controller — it must be registered before any cards render.
    final WishlistController ctrl = Get.find<WishlistController>();
    return Obx(() {
      final wishlisted = ctrl.isWishlisted(productId);
      return MCircularIcon(
        icon: wishlisted ? Iconsax.heart5 : Iconsax.heart,
        color: wishlisted ? Colors.red : Colors.grey,
        onPressed: productId.isEmpty
            ? null
            : () => ctrl.toggleWishlist(productId, productData),
      );
    });
  }
}
