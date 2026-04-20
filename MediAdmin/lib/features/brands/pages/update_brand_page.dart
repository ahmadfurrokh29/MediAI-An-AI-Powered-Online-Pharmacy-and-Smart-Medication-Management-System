import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../categories/controllers/category_controller.dart';
import '../controllers/brand_controller.dart';
import '../models/brand_model.dart';

class UpdateBrandPage extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic> brand;

  const UpdateBrandPage({super.key, required this.onBack, required this.brand});

  @override
  State<UpdateBrandPage> createState() => _UpdateBrandPageState();
}

class _UpdateBrandPageState extends State<UpdateBrandPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late bool featured;
  late bool active;
  late Set<String> selectedCategoryIds;
  bool isLoading = false;

  final categoryController = Get.find<CategoryController>();
  final brandController = Get.find<BrandController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.brand['name']);
    featured = widget.brand['isFeatured'] ?? false;
    active = widget.brand['isActive'] ?? true;
    selectedCategoryIds = Set<String>.from(
      widget.brand['categoryIds'] ?? <String>[],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategoryIds.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one category',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final updated = BrandModel(
        id: widget.brand['id'],
        name: _nameController.text.trim(),
        image: widget.brand['image'] ?? '',
        categoryIds: selectedCategoryIds.toList(),
        isFeatured: featured,
        isActive: active,
        productCount: widget.brand['productCount'] ?? 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await brandController.updateBrand(updated);
      await brandController.fetchBrands();
      widget.onBack();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update brand: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 10),
            const Text(
              "Update Brand",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(30),
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Brand Name",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter brand name';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter brand name',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Select Categories",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Obx(() {
                        if (categoryController.categories.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'No categories available.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: categoryController.categories.map((cat) {
                            final isSelected = selectedCategoryIds.contains(
                              cat.id,
                            );
                            return FilterChip(
                              label: Text(cat.name),
                              selected: isSelected,
                              selectedColor: Colors.green.shade100,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    selectedCategoryIds.add(cat.id);
                                  } else {
                                    selectedCategoryIds.remove(cat.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      }),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text(
                            "Featured",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 20),
                          Switch(
                            value: featured,
                            activeThumbColor: Colors.green,
                            onChanged: (val) {
                              setState(() => featured = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            "Status",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 20),
                          Switch(
                            value: active,
                            activeThumbColor: Colors.green,
                            onChanged: (val) {
                              setState(() => active = val);
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            active ? "Active" : "Inactive",
                            style: TextStyle(
                              color: active ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4299E1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: isLoading ? null : _handleUpdate,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Update",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
