import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/products_table.dart';
import '../controllers/product_controller.dart';
import '../../categories/controllers/category_controller.dart';
import '../../brands/controllers/brand_controller.dart';

class ProductsPage extends StatefulWidget {
  final VoidCallback onCreatePressed;
  final Function(Map<String, dynamic>)? onEditPressed;

  const ProductsPage({
    super.key,
    required this.onCreatePressed,
    this.onEditPressed,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  void initState() {
    super.initState();
    // Initialize data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<ProductController>();
      final categoryController = Get.find<CategoryController>();
      final brandController = Get.find<BrandController>();

      controller.initialize();
      categoryController.initialize();
      brandController.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();
    final categoryController = Get.find<CategoryController>();
    final brandController = Get.find<BrandController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: widget.onCreatePressed,
                  child: const Text(
                    "Create New Product",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Obx(
                  () => Text(
                    'Total Products: ${controller.products.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                IconButton(icon: const Icon(Icons.download), onPressed: () {}),
                IconButton(icon: const Icon(Icons.print), onPressed: () {}),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Search and Filters Row
        Row(
          children: [
            // Search field
            Expanded(
              flex: 3,
              child: TextField(
                onChanged: (value) {
                  controller.searchQuery.value = value;
                },
                decoration: InputDecoration(
                  hintText: "Search products...",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Category Filter
            Expanded(
              flex: 2,
              child: Obx(() {
                return DropdownButtonFormField<String>(
                  initialValue: controller.selectedCategoryFilter.value.isEmpty
                      ? null
                      : controller.selectedCategoryFilter.value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Filter by Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
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
                  onChanged: (value) {
                    controller.selectedCategoryFilter.value = value ?? '';
                  },
                );
              }),
            ),

            const SizedBox(width: 16),

            // Brand Filter
            Expanded(
              flex: 2,
              child: Obx(() {
                return DropdownButtonFormField<String>(
                  initialValue: controller.selectedBrandFilter.value.isEmpty
                      ? null
                      : controller.selectedBrandFilter.value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Filter by Brand',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All Brands'),
                    ),
                    ...brandController.brands.map(
                      (brand) => DropdownMenuItem(
                        value: brand.id,
                        child: Text(brand.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    controller.selectedBrandFilter.value = value ?? '';
                  },
                );
              }),
            ),

            const SizedBox(width: 16),

            // Clear Filters Button
            ElevatedButton.icon(
              onPressed: () {
                controller.clearFilters();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Expanded(child: ProductsTable(onEditPressed: widget.onEditPressed)),

        const SizedBox(height: 10),

        Obx(
          () => Text(
            "Showing ${controller.filteredProducts.length} of ${controller.products.length} Products",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
