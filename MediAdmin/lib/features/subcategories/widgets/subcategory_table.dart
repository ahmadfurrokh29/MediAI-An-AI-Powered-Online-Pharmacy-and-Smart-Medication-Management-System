import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subcategory_controller.dart';
import 'package:intl/intl.dart';

class SubcategoryTable extends StatelessWidget {
  final Function(Map<String, dynamic>)? onEditPressed;

  const SubcategoryTable({super.key, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubcategoryController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Obx(() {
        if (controller.isLoading.value && controller.subcategories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredSubcategories.isEmpty) {
          return const Center(
            child: Text(
              'No subcategories found. Create your first subcategory!',
            ),
          );
        }

        return SingleChildScrollView(
          child: DataTable(
            columnSpacing: 50,
            horizontalMargin: 20,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text("Sub Category")),
              DataColumn(label: Text("Category")),
              DataColumn(label: Text("Featured")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Action")),
            ],
            rows: controller.filteredSubcategories.map((sub) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(
                        sub.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  DataCell(
                    Chip(
                      label: Text(sub.categoryName),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ),
                  DataCell(
                    Switch(
                      value: sub.isFeatured,
                      activeThumbColor: Colors.green,
                      onChanged: (val) {
                        controller.toggleFeatured(sub.id, val);
                      },
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Switch(
                          value: sub.isActive,
                          activeThumbColor: Colors.green,
                          onChanged: (val) {
                            controller.toggleActive(sub.id, val);
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sub.isActive ? "Active" : "Inactive",
                          style: TextStyle(
                            color: sub.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(DateFormat('dd/MM/yyyy').format(sub.createdAt)),
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
                          tooltip: 'Edit Subcategory',
                          onPressed: () {
                            if (onEditPressed != null) {
                              onEditPressed!({
                                'id': sub.id,
                                'name': sub.name,
                                'categoryId': sub.categoryId,
                                'categoryName': sub.categoryName,
                                'image': sub.image,
                                'isFeatured': sub.isFeatured,
                                'isActive': sub.isActive,
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            Get.dialog(
                              AlertDialog(
                                title: const Text('Delete Subcategory'),
                                content: Text(
                                  'Are you sure you want to delete "${sub.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.back();
                                      controller.deleteSubcategory(sub.id);
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
