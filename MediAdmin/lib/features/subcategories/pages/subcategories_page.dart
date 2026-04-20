import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/subcategory_table.dart';
import '../controllers/subcategory_controller.dart';

class SubcategoriesPage extends StatefulWidget {
  final VoidCallback onCreatePressed;
  final Function(Map<String, dynamic>)? onEditPressed;

  const SubcategoriesPage({
    super.key,
    required this.onCreatePressed,
    this.onEditPressed,
  });

  @override
  State<SubcategoriesPage> createState() => _SubcategoriesPageState();
}

class _SubcategoriesPageState extends State<SubcategoriesPage> {
  @override
  void initState() {
    super.initState();
    // Initialize data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<SubcategoryController>();
      controller.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubcategoryController>();

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
                    "Create Sub-Category",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Obx(
                  () => Text(
                    'Total Subcategories: ${controller.subcategories.length}',
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
            hintText: "Search subcategories...",
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

        Expanded(child: SubcategoryTable(onEditPressed: widget.onEditPressed)),

        const SizedBox(height: 10),

        Obx(
          () => Text(
            "Showing ${controller.filteredSubcategories.length} of ${controller.subcategories.length} Subcategories",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
