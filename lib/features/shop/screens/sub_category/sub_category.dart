import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/products/product_cards/product_card_horizontal.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/shop/controllers/sub_category_controller.dart';
import 'package:med/features/shop/screens/all_products/all_products.dart';
import 'package:med/utils/constants/sizes.dart';

class SubCategoriesScreen extends StatefulWidget {
  const SubCategoriesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryBannerUrl,
  });

  /// Firestore document id of the parent category.
  final String categoryId;

  /// Displayed in the app bar.
  final String categoryName;

  /// Network URL for the category banner image (the category's Image field).
  final String? categoryBannerUrl;

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  late final SubCategoryController _controller;

  @override
  void initState() {
    super.initState();
    // Use a unique tag per category so navigating to multiple categories
    // simultaneously is safe, and the controller is not recreated on rebuild.
    _controller = Get.put(SubCategoryController(), tag: widget.categoryId);
    // Load data once after the first frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.loadSubCategories(widget.categoryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String bannerUrl = (widget.categoryBannerUrl ?? '').trim();

    return Scaffold(
      appBar: MAppBar(title: Text(widget.categoryName), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Category Banner ─────────────────────────────────────────
              if (bannerUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(MSizes.md),
                  child: Image.network(
                    bannerUrl,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : SizedBox(
                            height: 160,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          ),
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                )
              else
                // Fallback placeholder banner when no URL is provided
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(MSizes.md),
                  ),
                  child: Center(
                    child: Text(
                      widget.categoryName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),

              const SizedBox(height: MSizes.spaceBtwSections),

              // ── Sub-category sections ───────────────────────────────────
              Obx(() {
                // ── Loading state ─────────────────────────────────────────
                if (_controller.isLoading.value) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // ── Error state ───────────────────────────────────────────
                if (_controller.errorMessage.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Something went wrong. Please try again.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              _controller.loadSubCategories(widget.categoryId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // ── Empty state ───────────────────────────────────────────
                if (_controller.subCategories.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'No subcategories found for this category.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // ── Subcategory list ──────────────────────────────────────
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _controller.subCategories.map((sub) {
                    final subName = (sub['name'] as String?) ?? '';
                    final products = List<Map<String, dynamic>>.from(
                      (sub['products'] as List?) ?? [],
                    );

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: MSizes.spaceBtwSections,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Heading + "View all" button ───────────────
                          MSectionHeading(
                            title: subName,
                            showActionButton: products.isNotEmpty,
                            onPressed: products.isEmpty
                                ? null
                                : () => Get.to(
                                    () => AllProducts(
                                      title: subName,
                                      products: products,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: MSizes.spaceBtwItems / 2),

                          // ── Products horizontal scroll ────────────────
                          if (products.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: MSizes.sm,
                              ),
                              child: Text(
                                'No products yet in this subcategory.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                          else
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: products.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: MSizes.spaceBtwItems),
                                itemBuilder: (context, index) =>
                                    MProductCardHorizontal(
                                      productData: products[index],
                                    ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
