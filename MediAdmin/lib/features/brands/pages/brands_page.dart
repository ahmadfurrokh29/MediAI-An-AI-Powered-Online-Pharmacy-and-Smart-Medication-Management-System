import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/brands_table.dart';
import '../controllers/brand_controller.dart';

class BrandsPage extends StatefulWidget {
  final VoidCallback onCreatePressed;
  final Function(Map<String, dynamic>)? onEditPressed;

  const BrandsPage({
    super.key,
    required this.onCreatePressed,
    this.onEditPressed,
  });

  @override
  State<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends State<BrandsPage> {
  @override
  void initState() {
    super.initState();
    // Initialize data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<BrandController>();
      controller.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BrandController>();

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
                    "Create New Brand",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Obx(
                  () => Text(
                    'Total Brands: ${controller.brands.length}',
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

        TextField(
          onChanged: (value) {
            controller.searchQuery.value = value;
          },
          decoration: InputDecoration(
            hintText: "Search brands...",
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),

        const SizedBox(height: 20),

        Expanded(child: BrandsTable(onEditPressed: widget.onEditPressed)),

        const SizedBox(height: 10),

        Obx(
          () => Text(
            "Showing ${controller.filteredBrands.length} of ${controller.brands.length} Brands",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
