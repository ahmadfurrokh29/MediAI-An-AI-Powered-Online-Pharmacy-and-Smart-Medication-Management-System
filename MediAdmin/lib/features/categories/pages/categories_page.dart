import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import '../widgets/category_table.dart';

class CategoriesPage extends StatefulWidget {
  final VoidCallback onCreatePressed;
  final Function(Map<String, dynamic>)? onEditPressed;

  const CategoriesPage({
    super.key,
    required this.onCreatePressed,
    this.onEditPressed,
  });

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<CategoryController>();
      controller.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CategoryController>();

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
                    "Create New Category",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Obx(
                  () => Text(
                    'Total Categories: ${controller.categories.length}',
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
          onChanged: (value) => controller.updateSearchQuery(value),
          decoration: InputDecoration(
            hintText: "Search categories...",
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

        Expanded(child: CategoryTable(onEditPressed: widget.onEditPressed)),

        const SizedBox(height: 10),

        Obx(
          () => Text(
            "Showing ${controller.filteredCategories.length} of ${controller.categories.length} Categories",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
