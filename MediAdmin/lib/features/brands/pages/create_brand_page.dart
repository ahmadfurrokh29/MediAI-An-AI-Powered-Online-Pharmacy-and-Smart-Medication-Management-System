import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../categories/controllers/category_controller.dart';
import '../controllers/brand_controller.dart';
import '../models/brand_model.dart';
import '../../../services/cloudinary_service.dart';

class CreateBrandPage extends StatefulWidget {
  final VoidCallback onBack;

  const CreateBrandPage({super.key, required this.onBack});

  @override
  State<CreateBrandPage> createState() => _CreateBrandPageState();
}

class _CreateBrandPageState extends State<CreateBrandPage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool featured = false;
  bool active = true;
  bool isLoading = false;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  final Set<String> selectedCategoryIds = {};

  final categoryController = Get.find<CategoryController>();
  final brandController = Get.find<BrandController>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();
    await uploadInput.onChange.first;
    if (uploadInput.files!.isEmpty) return;
    final file = uploadInput.files![0];
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    setState(() {
      _pickedImageBytes = reader.result as Uint8List;
      _pickedImageName = file.name;
    });
  }

  Future<void> _createBrand() async {
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

    setState(() {
      isLoading = true;
    });

    try {
      String imageUrl = '';
      String pickedPublicId = '';
      if (_pickedImageBytes != null) {
        final result = await CloudinaryService.uploadImage(
          bytes: _pickedImageBytes!,
          fileName: _pickedImageName ?? 'brand_logo.png',
          folder: 'brands',
        );
        imageUrl = result.url;
        pickedPublicId = result.publicId;
      }

      final brand = BrandModel(
        id: '',
        name: _nameController.text.trim(),
        image: imageUrl,
        publicId: pickedPublicId,
        categoryIds: selectedCategoryIds.toList(),
        isFeatured: featured,
        isActive: active,
        productCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await brandController.createBrand(brand);

      Get.snackbar(
        'Success',
        'Brand created successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );

      widget.onBack();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create brand: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
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
              "Create Brand",
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
                        if (categoryController.isLoading.value &&
                            categoryController.categories.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (categoryController.categories.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'No categories available. Please create a category first.',
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
                              setState(() {
                                featured = val;
                              });
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
                              setState(() {
                                active = val;
                              });
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

                      const SizedBox(height: 20),

                      const Text(
                        "Upload Logo",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _pickedImageBytes != null
                                  ? const Color(0xFF4299E1)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade50,
                          ),
                          child: _pickedImageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.memory(
                                    _pickedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.upload,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Upload',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: isLoading ? null : _createBrand,
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
                                  "Create",
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
