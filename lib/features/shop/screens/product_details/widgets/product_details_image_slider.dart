import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/custom_shapes/curved_edges/curved_edges_widget.dart';
import 'package:med/common/widgets/icons/circular_icon.dart';
import 'package:med/common/widgets/images/m_rounded_image.dart';
import 'package:med/features/shop/controllers/wishlist_controller.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MProductImageSlider extends StatefulWidget {
  const MProductImageSlider({
    super.key,
    required this.images,
    this.productId = '',
    this.productData,
  });

  /// List of image URLs (network) or asset paths (local).
  final List<String> images;
  final String productId;
  final Map<String, dynamic>? productData;

  @override
  State<MProductImageSlider> createState() => _MProductImageSliderState();
}

class _MProductImageSliderState extends State<MProductImageSlider> {
  int _selected = 0;

  List<String> get _images =>
      widget.images.isNotEmpty ? widget.images : [MImages.product10];

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final current = _images[_selected];
    final isNetwork =
        current.startsWith('http://') || current.startsWith('https://');

    return MCurvedEdgeWidget(
      child: Container(
        color: dark ? MColors.darkerGrey : MColors.light,
        child: Stack(
          children: [
            /// Main image
            SizedBox(
              height: 400,
              child: Padding(
                padding: const EdgeInsets.all(MSizes.defaultSpace * 2),
                child: Center(
                  child: MRoundedImage(
                    imageUrl: current,
                    isNetworkImage: isNetwork,
                    applyImageRadius: true,
                  ),
                ),
              ),
            ),

            /// App Bar (Back Arrow + Wishlist heart)
            MAppBar(
              showBackArrow: true,
              actions: [_WishlistHeartButton(
                productId: widget.productId,
                productData: widget.productData,
              )],
            ),

            /// Thumbnail strip
            Positioned(
              right: 0,
              bottom: 30,
              left: MSizes.defaultSpace,
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  itemCount: _images.length,
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: MSizes.spaceBtwItems),
                  itemBuilder: (_, index) {
                    final thumb = _images[index];
                    final thumbNet =
                        thumb.startsWith('http://') ||
                        thumb.startsWith('https://');
                    return GestureDetector(
                      onTap: () => setState(() => _selected = index),
                      child: MRoundedImage(
                        width: 80,
                        backgroundColor: dark ? MColors.dark : MColors.white,
                        border: Border.all(
                          color: _selected == index
                              ? MColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                        padding: const EdgeInsets.all(MSizes.sm),
                        imageUrl: thumb,
                        isNetworkImage: thumbNet,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wishlist heart icon that toggles via WishlistController.
class _WishlistHeartButton extends StatelessWidget {
  const _WishlistHeartButton({required this.productId, this.productData});
  final String productId;
  final Map<String, dynamic>? productData;

  @override
  Widget build(BuildContext context) {
    if (productId.isEmpty) {
      return const MCircularIcon(icon: Iconsax.heart5, color: Colors.red);
    }
    final ctrl = Get.find<WishlistController>();
    return Obx(() {
      final wishlisted = ctrl.isWishlisted(productId);
      return MCircularIcon(
        icon: wishlisted ? Iconsax.heart5 : Iconsax.heart,
        color: wishlisted ? Colors.red : Colors.grey,
        onPressed: () => ctrl.toggleWishlist(productId, productData),
      );
    });
  }
}
