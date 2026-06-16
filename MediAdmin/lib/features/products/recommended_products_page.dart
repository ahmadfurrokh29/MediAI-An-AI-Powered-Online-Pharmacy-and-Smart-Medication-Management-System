import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'controllers/product_controller.dart';
import '../categories/controllers/category_controller.dart';

class RecommendedProductsPage extends StatefulWidget {
  const RecommendedProductsPage({super.key});

  @override
  State<RecommendedProductsPage> createState() =>
      _RecommendedProductsPageState();
}

class _RecommendedProductsPageState extends State<RecommendedProductsPage> {
  final TextEditingController searchController = TextEditingController();

  int visibleCount = 14;

  List<Map<String, dynamic>> allProducts = List.generate(
    30,
    (index) => {
      "name": "Product ${index + 1}",
      "price": (50 + index * 3).toDouble(),
      "recommended": false,
      "stock": 10 + index,
      "date": "08/02/2026",
    },
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ProductController>().initialize();
      Get.find<CategoryController>().initialize();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();
    final categoryController = Get.find<CategoryController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top bar: stats + actions ──────────────────────────────────────
        Row(
          children: [
            Obx(() {
              final total = controller.products.length;
              final recommended = controller.recommendedCount;
              return Row(
                children: [
                  _StatBadge(
                    label: 'Total Products',
                    value: '$total',
                    color: Colors.blue.shade50,
                    textColor: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  _StatBadge(
                    label: 'Recommended',
                    value: '$recommended',
                    color: Colors.green.shade50,
                    textColor: Colors.green.shade700,
                  ),
                ],
              );
            }),
            const Spacer(),
            IconButton(
              tooltip: 'Print',
              icon: const Icon(Icons.print_outlined),
              onPressed: () {},
            ),
            IconButton(
              tooltip: 'Download',
              icon: const Icon(Icons.download_outlined),
              onPressed: () {},
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Search + Category filter ──────────────────────────────────────
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: searchController,
                onChanged: (value) =>
                    controller.recommendedSearchQuery.value = value,
                decoration: InputDecoration(
                  hintText: 'Search by product name, category or subcategory…',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Obx(() {
                return DropdownButtonFormField<String>(
                  initialValue:
                      controller.recommendedCategoryFilter.value.isEmpty
                      ? null
                      : controller.recommendedCategoryFilter.value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Filter by Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All Categories'),
                    ),
                    ...categoryController.categories.map(
                      (cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      controller.recommendedCategoryFilter.value = value ?? '',
                );
              }),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                searchController.clear();
                controller.clearRecommendedFilters();
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Table ─────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final displayList = controller.recommendedFilteredProducts;

              if (displayList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.products.isEmpty
                            ? 'No products yet.\nCreate products first in the Products section.'
                            : 'No products match your search.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 350,
                    ),
                    child: DataTable(
                      columnSpacing: 50,
                      horizontalMargin: 20,
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey.shade100,
                      ),
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 72,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Product',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Category',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Subcategory',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Price',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Stock',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Recommended',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Added',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      rows: displayList.map((product) {
                        return DataRow(
                          cells: [
                            // Product name + brand
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    if (product.brandName.isNotEmpty)
                                      Text(
                                        product.brandName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Category badge
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  product.categoryName.isEmpty
                                      ? '—'
                                      : product.categoryName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            // Subcategory
                            DataCell(
                              Text(
                                product.subcategoryName.isEmpty
                                    ? '—'
                                    : product.subcategoryName,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),

                            // Price
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Rs ${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (product.salePrice > 0 &&
                                      product.salePrice < product.price)
                                    Text(
                                      'Sale: Rs ${product.salePrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Stock badge
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: product.stock > 10
                                      ? Colors.green.shade50
                                      : product.stock > 0
                                      ? Colors.orange.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${product.stock}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: product.stock > 10
                                        ? Colors.green.shade700
                                        : product.stock > 0
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ),

                            // Recommended toggle
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: product.isRecommended,
                                    activeThumbColor: Colors.green,
                                    onChanged: (val) => controller
                                        .toggleRecommended(product.id, val),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.isRecommended ? 'On' : 'Off',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: product.isRecommended
                                          ? Colors.green.shade700
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Date added
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(product.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 10),

        Obx(
          () => Text(
            "Showing ${controller.recommendedFilteredProducts.length} of ${controller.products.length} Products",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// Small stat badge used in the top bar.
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
