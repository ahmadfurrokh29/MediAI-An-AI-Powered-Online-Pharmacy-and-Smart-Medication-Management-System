import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/features/shop/controllers/home_controller.dart';
import 'package:med/features/shop/screens/product_details/product_details.dart';

/// Opens a bottom sheet with a live search field that queries Firestore products.
/// Tapping a result navigates to the product detail page.
void openProductSearchSheet(BuildContext context) {
  // Ensure HomeController is available
  final controller = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());

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
                  onChanged: controller.searchProducts,
                  decoration: InputDecoration(
                    hintText: 'Search products, brands, categories…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.searchResults.clear();
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
                    if (controller.searchResults.isEmpty) {
                      return const Center(
                        child: Text('Start typing to search…'),
                      );
                    }
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: controller.searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = controller.searchResults[i];
                        final image = (p['image'] ?? '').toString();
                        final isNetwork = image.startsWith('http');
                        return ListTile(
                          onTap: () {
                            Navigator.pop(ctx);
                            Get.to(() => MProductDetail(productData: p));
                          },
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isNetwork
                                ? Image.network(
                                    image,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
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
                            'Rs ${(p['price'] ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
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
