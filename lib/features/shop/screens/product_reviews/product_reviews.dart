import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/products/rating/rating_indicator.dart';
import 'package:med/features/shop/controllers/review_controller.dart';
import 'package:med/features/shop/screens/product_reviews/widgets/rating_progress_indicator.dart';
import 'package:med/features/shop/screens/product_reviews/widgets/user_review_card.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';

class ProductReviewsScreen extends StatelessWidget {
  const ProductReviewsScreen({
    super.key,
    required this.productId,
    this.productData,
  });

  final String productId;
  final Map<String, dynamic>? productData;

  @override
  Widget build(BuildContext context) {
    // Register a fresh ReviewController scoped to this product
    final controller = Get.put(ReviewController(), tag: productId);
    // Fetch reviews when screen opens
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.fetchReviews(productId),
    );

    return Scaffold(
      appBar: MAppBar(
        title: const Text('Reviews and Ratings'),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Constant header statement
              const Text(
                'Ratings and reviews are verified and come from people who use the same type of medicine that you use.',
              ),
              const SizedBox(height: MSizes.spaceBtwItems),

              /// Overall rating block — reactive
              Obx(() {
                final avg = controller.avgRating;
                final count = controller.reviewCount;
                final counts = controller.ratingCounts;

                return Column(
                  children: [
                    MOverallProductRating(
                      avgRating: avg,
                      reviewCount: count,
                      ratingCounts: counts,
                    ),
                    const SizedBox(height: MSizes.spaceBtwItems / 2),
                    Row(
                      children: [
                        MRatingBarIndicator(rating: avg),
                        const SizedBox(width: MSizes.spaceBtwItems),
                        Text(
                          '$count review${count == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                );
              }),

              const SizedBox(height: MSizes.spaceBtwSections),

              /// ─── Add Review form ───────────────────────────────────────
              _AddReviewForm(controller: controller, productId: productId),

              const Divider(height: MSizes.spaceBtwSections * 2),

              /// ─── Reviews list ──────────────────────────────────────────
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.reviews.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('No reviews yet. Be the first!'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.reviews.length,
                  itemBuilder: (_, i) =>
                      UserReviewCard(review: controller.reviews[i]),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Inline add-review form ────────────────────────────────────────────────
class _AddReviewForm extends StatelessWidget {
  const _AddReviewForm({required this.controller, required this.productId});

  final ReviewController controller;
  final String productId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Your Review', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: MSizes.spaceBtwItems),

        /// Star selector
        Obx(
          () => Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => controller.selectedRating.value = star.toDouble(),
                child: Icon(
                  star <= controller.selectedRating.value
                      ? Iconsax.star5
                      : Iconsax.star,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: MSizes.spaceBtwItems),

        /// Comment field
        TextField(
          controller: controller.commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Write your comment here…',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MSizes.cardRadiusMd),
            ),
          ),
        ),

        const SizedBox(height: MSizes.spaceBtwItems),

        /// Submit button
        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isSubmitting.value
                  ? null
                  : () => controller.submitReview(productId),
              icon: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MColors.white,
                      ),
                    )
                  : const Icon(Iconsax.send_1),
              label: Text(
                controller.isSubmitting.value ? 'Submitting…' : 'Submit Review',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
