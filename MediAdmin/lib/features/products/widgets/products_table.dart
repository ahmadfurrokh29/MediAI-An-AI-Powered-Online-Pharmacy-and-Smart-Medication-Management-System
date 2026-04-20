import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import 'package:intl/intl.dart';

class ProductsTable extends StatelessWidget {
  final Function(Map<String, dynamic>)? onEditPressed;

  const ProductsTable({super.key, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Obx(() {
        if (controller.isLoading.value && controller.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredProducts.isEmpty) {
          return const Center(
            child: Text('No products found. Create your first product!'),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 50,
              horizontalMargin: 20,
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text("Product")),
                DataColumn(label: Text("Category")),
                DataColumn(label: Text("Brand")),
                DataColumn(label: Text("Price")),
                DataColumn(label: Text("Stock")),
                DataColumn(label: Text("Featured")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Action")),
              ],
              rows: controller.filteredProducts.map((product) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (product.subcategoryName.isNotEmpty)
                              Text(
                                product.subcategoryName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    DataCell(
                      Chip(
                        label: Text(product.categoryName),
                        backgroundColor: Colors.blue.shade50,
                      ),
                    ),

                    DataCell(
                      Chip(
                        label: Text(product.brandName),
                        backgroundColor: Colors.green.shade50,
                      ),
                    ),

                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: product.salePrice > 0
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: product.salePrice > 0
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          if (product.salePrice > 0)
                            Text(
                              '\$${product.salePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),

                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: product.stock > 10
                              ? Colors.green.shade50
                              : product.stock > 0
                              ? Colors.orange.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.stock.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: product.stock > 10
                                ? Colors.green.shade900
                                : product.stock > 0
                                ? Colors.orange.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ),

                    DataCell(
                      Switch(
                        value: product.isFeatured,
                        activeThumbColor: Colors.green,
                        onChanged: (val) {
                          controller.toggleFeatured(product.id, val);
                        },
                      ),
                    ),

                    DataCell(
                      Row(
                        children: [
                          Switch(
                            value: product.isActive,
                            activeThumbColor: Colors.green,
                            onChanged: (val) {
                              controller.toggleActive(product.id, val);
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            product.isActive ? "Active" : "Inactive",
                            style: TextStyle(
                              color: product.isActive
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    DataCell(
                      Text(DateFormat('dd/MM/yyyy').format(product.createdAt)),
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
                            tooltip: 'Edit Product',
                            onPressed: () {
                              if (onEditPressed != null) {
                                onEditPressed!({
                                  'id': product.id,
                                  'name': product.name,
                                  'formulaName': product.formulaName,
                                  'description': product.description,
                                  'price': product.price,
                                  'salePrice': product.salePrice,
                                  'stock': product.stock,
                                  'images': product.images,
                                  'categoryId': product.categoryId,
                                  'categoryName': product.categoryName,
                                  'subcategoryId': product.subcategoryId,
                                  'subcategoryName': product.subcategoryName,
                                  'brandId': product.brandId,
                                  'brandName': product.brandName,
                                  'isFeatured': product.isFeatured,
                                  'isRecommended': product.isRecommended,
                                  'isActive': product.isActive,
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Get.dialog(
                                AlertDialog(
                                  title: const Text('Delete Product'),
                                  content: Text(
                                    'Are you sure you want to delete "${product.name}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Get.back();
                                        controller.deleteProduct(product.id);
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
          ),
        );
      }),
    );
  }
}
