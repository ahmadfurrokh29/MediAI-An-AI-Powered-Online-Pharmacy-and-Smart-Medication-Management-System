import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';

class UpdateCategoryPage extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic> category;

  const UpdateCategoryPage({
    super.key,
    required this.onBack,
    required this.category,
  });

  @override
  State<UpdateCategoryPage> createState() => _UpdateCategoryPageState();
}

class _UpdateCategoryPageState extends State<UpdateCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final controller = Get.find<CategoryController>();
  late bool featured;
  late bool active;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category['name']);
    featured = widget.category['isFeatured'] ?? false;
    active = widget.category['isActive'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      final updated = CategoryModel(
        id: widget.category['id'],
        name: _nameController.text.trim(),
        image: widget.category['image'] ?? '',
        isFeatured: featured,
        isActive: active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await controller.updateCategory(updated);
      await controller.fetchCategories();
      widget.onBack();
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
              "Update Category",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Center(
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
                  const Text("Category Name"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter category name';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter category name',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text("Featured"),
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
                      const Text("Status"),
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
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4299E1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: controller.isLoading.value
                            ? null
                            : _handleUpdate,
                        child: controller.isLoading.value
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
