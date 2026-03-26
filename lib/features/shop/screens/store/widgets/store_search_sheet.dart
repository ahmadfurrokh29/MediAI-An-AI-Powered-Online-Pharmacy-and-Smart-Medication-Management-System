import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/features/shop/controllers/store_controller.dart';
import 'package:med/features/shop/screens/brand/brand_products.dart';
import 'package:med/features/shop/screens/product_details/product_details.dart';

/// Opens a bottom sheet that searches both products AND brands.
void openStoreSearchSheet(BuildContext context) {
  final controller = Get.isRegistered<StoreController>()
      ? Get.find<StoreController>()
      : Get.put(StoreController());

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  autofocus: true,
                  onChanged: controller.searchStore,
                  decoration: InputDecoration(
                    hintText: 'Search products, brands…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.searchResults.clear();
                        controller.brandSearchResults.clear();
                        Navigator.pop(ctx);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Results
                Expanded(
                  child: Obx(() {
                    if (controller.isSearching.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final brands = controller.brandSearchResults;
                    final products = controller.searchResults;

                    if (brands.isEmpty && products.isEmpty) {
                      return const Center(
                        child: Text('Start typing to search…'),
                      );
                    }

                    return ListView(
                      controller: scrollCtrl,
                      children: [
                        // ── Brand results ──
                        if (brands.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Brands',
                              style: Theme.of(ctx).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...brands.map((b) {
                            final name = (b['name'] ?? '').toString();
                            final image = (b['image'] ?? '').toString();
                            final isNet = image.startsWith('http');
                            final count = b['productCount'] ?? 0;
                            return ListTile(
                              onTap: () {
                                Navigator.pop(ctx);
                                Get.to(
                                  () => BrandProducts(
                                    brandName: name,
                                    brandImage: image,
                                    brandProductCount: count is int
                                        ? count
                                        : int.tryParse(count.toString()) ?? 0,
                                  ),
                                );
                              },
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: isNet
                                    ? Image.network(
                                        image,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.business,
                                              size: 32,
                                            ),
                                      )
                                    : const Icon(Icons.business, size: 32),
                              ),
                              title: Text(name),
                              subtitle: Text('$count products'),
                            );
                          }),
                          const Divider(),
                        ],

                        // ── Product results ──
                        if (products.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Products',
                              style: Theme.of(ctx).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...products.map((p) {
                            final image = (p['image'] ?? '').toString();
                            final isNet = image.startsWith('http');
                            return ListTile(
                              onTap: () {
                                Navigator.pop(ctx);
                                Get.to(() => MProductDetail(productData: p));
                              },
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: isNet
                                    ? Image.network(
                                        image,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.medication,
                                              size: 40,
                                            ),
                                      )
                                    : const Icon(Icons.medication, size: 40),
                              ),
                              title: Text((p['name'] ?? '').toString()),
                              subtitle: Text(
                                '${p['brandName'] ?? ''} • ${p['categoryName'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                'Rs ${((p['price'] ?? 0) as num).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  }),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
