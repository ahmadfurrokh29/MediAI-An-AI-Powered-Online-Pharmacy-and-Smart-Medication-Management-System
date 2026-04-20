import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/brand_controller.dart';
import 'package:intl/intl.dart';

class BrandsTable extends StatelessWidget {
  final Function(Map<String, dynamic>)? onEditPressed;

  const BrandsTable({super.key, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BrandController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Obx(() {
        if (controller.isLoading.value && controller.brands.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredBrands.isEmpty) {
          return const Center(
            child: Text('No brands found. Create your first brand!'),
          );
        }

        return SingleChildScrollView(
          child: DataTable(
            columnSpacing: 50,
            horizontalMargin: 20,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text("Brand")),
              DataColumn(label: Text("Categories")),
              DataColumn(label: Text("Featured")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Action")),
            ],
            rows: controller.filteredBrands.map((brand) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            brand.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          brand.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.purple.shade100,
                      child: Text(
                        brand.categoryIds.length.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Switch(
                      value: brand.isFeatured,
                      activeThumbColor: Colors.green,
                      onChanged: (val) {
                        controller.toggleFeatured(brand.id, val);
                      },
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Switch(
                          value: brand.isActive,
                          activeThumbColor: Colors.green,
                          onChanged: (val) {
                            controller.toggleActive(brand.id, val);
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          brand.isActive ? "Active" : "Inactive",
                          style: TextStyle(
                            color: brand.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(DateFormat('dd/MM/yyyy').format(brand.createdAt)),
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
                          tooltip: 'Edit Brand',
                          onPressed: () {
                            if (onEditPressed != null) {
                              onEditPressed!({
                                'id': brand.id,
                                'name': brand.name,
                                'image': brand.image,
                                'categoryIds': brand.categoryIds,
                                'isFeatured': brand.isFeatured,
                                'isActive': brand.isActive,
                                'productCount': brand.productCount,
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            Get.dialog(
                              AlertDialog(
                                title: const Text('Delete Brand'),
                                content: Text(
                                  'Are you sure you want to delete "${brand.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.back();
                                      controller.deleteBrand(brand.id);
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
