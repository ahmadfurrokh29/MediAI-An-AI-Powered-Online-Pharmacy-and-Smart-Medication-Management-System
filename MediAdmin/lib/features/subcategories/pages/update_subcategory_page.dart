import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../categories/controllers/category_controller.dart';
import '../controllers/subcategory_controller.dart';
import '../models/subcategory_model.dart';

class UpdateSubcategoryPage extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic> subcategory;

  const UpdateSubcategoryPage({
    super.key,
    required this.onBack,
    required this.subcategory,
  });

  @override
  State<UpdateSubcategoryPage> createState() => _UpdateSubcategoryPageState();
}

class _UpdateSubcategoryPageState extends State<UpdateSubcategoryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late bool featured;
  late bool isActive;
  late String? selectedCategoryId;
  bool isLoading = false;

  final categoryController = Get.find<CategoryController>();
  final subcategoryController = Get.find<SubcategoryController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subcategory['name']);
    featured = widget.subcategory['isFeatured'] ?? false;
    isActive = widget.subcategory['isActive'] ?? true;
    selectedCategoryId = widget.subcategory['categoryId'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategoryId == null) {
      Get.snackbar(
        'Error',
        'Please select a parent category',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final category = categoryController.categories.firstWhere(
        (cat) => cat.id == selectedCategoryId,
      );

      final updated = SubcategoryModel(
        id: widget.subcategory['id'],
        name: _nameController.text.trim(),
        categoryId: selectedCategoryId!,
        categoryName: category.name,
        image: widget.subcategory['image'] ?? '',
        isFeatured: featured,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await subcategoryController.updateSubcategory(updated);
      await subcategoryController.fetchSubcategories();
      widget.onBack();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update subcategory: $e',
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
              "Update Sub Category",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(30),
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
                        "Sub Category Name",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter subcategory name';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter subcategory name',
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
                        "Parent Category",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
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
                        return DropdownButtonFormField<String>(
                          value: selectedCategoryId,
                          items: categoryController.categories
                              .map(
                                (cat) => DropdownMenuItem<String>(
                                  value: cat.id,
                                  child: Text(cat.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => selectedCategoryId = val);
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
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
                            value: isActive,
                            activeThumbColor: Colors.green,
                            onChanged: (val) {
                              setState(() => isActive = val);
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isActive ? "Active" : "Inactive",
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.red,
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
