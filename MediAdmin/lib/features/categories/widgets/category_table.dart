import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import 'package:intl/intl.dart';

class CategoryTable extends StatelessWidget {
  final Function(Map<String, dynamic>)? onEditPressed;

  const CategoryTable({super.key, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CategoryController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Obx(() {
        if (controller.isLoading.value && controller.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredCategories.isEmpty) {
          return const Center(
            child: Text('No categories found. Create your first category!'),
          );
        }

        return SingleChildScrollView(
          child: DataTable(
            columnSpacing: 50,
            horizontalMargin: 20,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text("Category")),
              DataColumn(label: Text("Featured")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Action")),
            ],
            rows: controller.filteredCategories.map((category) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  DataCell(
                    Switch(
                      value: category.isFeatured,
                      activeThumbColor: Colors.green,
                      onChanged: (val) {
                        controller.toggleFeatured(category.id, val);
                      },
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Switch(
                          value: category.isActive,
                          activeThumbColor: Colors.green,
                          onChanged: (val) {
                            controller.toggleActive(category.id, val);
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.isActive ? "Active" : "Inactive",
                          style: TextStyle(
                            color: category.isActive
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(DateFormat('dd/MM/yyyy').format(category.createdAt)),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF4299E1),
                          ),
                          tooltip: 'Edit Category',
                          onPressed: () {
                            if (onEditPressed != null) {
                              onEditPressed!({
                                'id': category.id,
                                'name': category.name,
                                'image': category.image,
                                'isFeatured': category.isFeatured,
                                'isActive': category.isActive,
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            Get.dialog(
                              AlertDialog(
                                title: const Text('Delete Category'),
                                content: Text(
                                  'Are you sure you want to delete "${category.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.back();
                                      controller.deleteCategory(category.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}
