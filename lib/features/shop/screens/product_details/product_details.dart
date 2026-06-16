import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/features/shop/screens/product_details/widgets/bottom_add_to_cart_widget.dart';
import 'package:med/features/shop/screens/product_details/widgets/product_details_image_slider.dart';
import 'package:med/features/shop/screens/product_details/widgets/product_meta_data.dart';
import 'package:med/features/shop/screens/product_details/widgets/rating_share_widget.dart';
import 'package:med/features/shop/screens/product_reviews/product_reviews.dart';
import 'package:med/features/shop/screens/checkout/checkout.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:readmore/readmore.dart';

class MProductDetail extends StatelessWidget {
  const MProductDetail({super.key, this.productData});

  /// Live product map from Firestore.
  final Map<String, dynamic>? productData;

  @override
  Widget build(BuildContext context) {
    final data = productData ?? {};

    // Resolve image list
    final rawImages = data['images'];
    final List<String> images = (rawImages is List)
        ? rawImages.map((e) => e.toString()).toList()
        : (rawImages != null ? [rawImages.toString()] : []);

    final String description = (data['description'] ?? '').toString();
    final double avgRating = (data['avgRating'] ?? 0).toDouble();
    final int reviewCount = ((data['reviewCount'] ?? 0) as num).toInt();
    final String productId = (data['id'] ?? '').toString();
    final String productName = (data['name'] ?? '').toString();

    return Scaffold(
      bottomNavigationBar: MBottomAddToCart(productData: data),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 1 – Image slider with live images + wishlist heart
            MProductImageSlider(
              images: images,
              productId: productId,
              productData: data,
            ),

            /// 2 – Product Details
            Padding(
              padding: const EdgeInsets.only(
                right: MSizes.defaultSpace,
                left: MSizes.defaultSpace,
                bottom: MSizes.defaultSpace,
              ),
              child: Column(
                children: [
                  /// Rating & Share
                  MRatingAndShare(
                    avgRating: avgRating,
                    reviewCount: reviewCount,
                    productName: productName,
                    productDescription: description,
                  ),

                  /// Meta: price, title, stock, brand
                  MProductMetaData(productData: data),

                  const SizedBox(height: MSizes.spaceBtwSections),

                  /// Checkout button (Buy Now – direct checkout for this product)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final cart = CartController.instance;
                        final success = await cart.buyNow(data);
                        if (success) {
                          Get.to(() => const CheckoutScreen());
                        }
                      },
                      child: const Text('Checkout'),
                    ),
                  ),

                  const SizedBox(height: MSizes.spaceBtwSections),

                  /// Description
                  const MSectionHeading(
                    title: 'Description',
                    showActionButton: false,
                  ),
                  const SizedBox(height: MSizes.spaceBtwItems),
                  ReadMoreText(
                    description.isNotEmpty
                        ? description
                        : 'No description available.',
                    trimLines: 3,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: ' Show more',
                    trimExpandedText: ' Show less',
                    moreStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    lessStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  /// Medicine Details (only if any field is set)
                  _MedicineDetailsSection(productData: data),

                  /// Reviews Section link
                  const Divider(),
                  const SizedBox(height: MSizes.spaceBtwItems),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MSectionHeading(
                        title: 'Reviews ($reviewCount)',
                        showActionButton: false,
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.arrow_right_3, size: 18),
                        onPressed: () => Get.to(
                          () => ProductReviewsScreen(
                            productId: productId,
                            productData: data,
                          ),
                        ),
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

/// Shown after description — only renders if at least one medicine field is set.
class _MedicineDetailsSection extends StatelessWidget {
  const _MedicineDetailsSection({required this.productData});

  final Map<String, dynamic> productData;

  @override
  Widget build(BuildContext context) {
    final bool isPrescribed = productData['isPrescribed'] ?? false;
    final String form = (productData['medicineForm'] ?? '').toString();
    final int tabletsInPack =
        ((productData['tabletsInPack'] ?? 0) as num).toInt();

    if (!isPrescribed && form.isEmpty && tabletsInPack <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: MSizes.spaceBtwSections),
        const MSectionHeading(
          title: 'Medicine Details',
          showActionButton: false,
        ),
        const SizedBox(height: MSizes.spaceBtwItems),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prescribed
            if (isPrescribed)
              _DetailRow(
                icon: Icons.medical_services_outlined,
                iconColor: Colors.blue.shade400,
                label: 'Prescribed',
                value: 'Yes — Prescription Required',
                bold: true,
              ),

            // Form
            if (form.isNotEmpty) ...[
              if (isPrescribed) const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.science_outlined,
                iconColor: Colors.teal.shade400,
                label: 'Form',
                value: form,
              ),
            ],

            // Tablets/Capsules in pack
            if (tabletsInPack > 0) ...[
              if (isPrescribed || form.isNotEmpty)
                const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.indigo.shade400,
                label: form.isNotEmpty ? '$form per Pack' : 'Units per Pack',
                value: tabletsInPack.toString(),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.bold = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label:  ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: iconColor.withValues(alpha: 0.7),
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: iconColor,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
