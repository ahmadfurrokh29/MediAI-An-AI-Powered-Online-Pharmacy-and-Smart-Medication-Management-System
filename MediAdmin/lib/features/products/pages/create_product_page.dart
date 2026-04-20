import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../categories/controllers/category_controller.dart';
import '../../subcategories/controllers/subcategory_controller.dart';
import '../../brands/controllers/brand_controller.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

class CreateProductPage extends StatefulWidget {
  final VoidCallback onBack;

  const CreateProductPage({super.key, required this.onBack});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _formulaController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool isFeatured = false; // For popular products in category
  bool isActive = true;
  bool isLoading = false;

  String? selectedCategoryId;
  String? selectedSubcategoryId;
  String? selectedBrandId;

  final categoryController = Get.find<CategoryController>();
  final subcategoryController = Get.find<SubcategoryController>();
  final brandController = Get.find<BrandController>();
  final productController = Get.find<ProductController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      categoryController.initialize();
      subcategoryController.initialize();
      brandController.initialize();
    });
  }

  // Returns true when the currently-selected category name contains "medicine"
  bool get _isMedicineCategory {
    if (selectedCategoryId == null) return false;
    try {
      final cat = categoryController.categories.firstWhere(
        (c) => c.id == selectedCategoryId,
      );
      return cat.name.toLowerCase().contains('medicine');
    } catch (_) {
      return false;
    }
  }

  // Filtered subcategories based on selected category
  List get filteredSubcategories {
    if (selectedCategoryId == null) return [];
    return subcategoryController.subcategories
        .where((sub) => sub.categoryId == selectedCategoryId)
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _formulaController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategoryId == null) {
      Get.snackbar(
        'Error',
        'Please select a category',
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    if (selectedBrandId == null) {
      Get.snackbar(
        'Error',
        'Please select a brand',
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final category = categoryController.categories.firstWhere(
        (cat) => cat.id == selectedCategoryId,
      );
      final brand = brandController.brands.firstWhere(
        (b) => b.id == selectedBrandId,
      );

      String subcategoryName = '';
      if (selectedSubcategoryId != null && selectedSubcategoryId!.isNotEmpty) {
        final subcategory = subcategoryController.subcategories.firstWhere(
          (sub) => sub.id == selectedSubcategoryId,
        );
        subcategoryName = subcategory.name;
      }

      final product = ProductModel(
        id: '',
        name: _nameController.text.trim(),
        formulaName: _formulaController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        salePrice: _salePriceController.text.isEmpty
            ? 0.0
            : double.parse(_salePriceController.text),
        stock: int.parse(_stockController.text),
        images: _imageUrlController.text.trim().isNotEmpty
            ? [_imageUrlController.text.trim()]
            : [],
        categoryId: selectedCategoryId!,
        categoryName: category.name,
        subcategoryId: selectedSubcategoryId ?? '',
        subcategoryName: subcategoryName,
        brandId: selectedBrandId!,
        brandName: brand.name,
        isFeatured: isFeatured,
        isRecommended: false,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await productController.createProduct(product);

      if (mounted) {
        Get.snackbar(
          'Success',
          'Product created successfully!',
          backgroundColor: Colors.green.shade100,
        );
        widget.onBack();
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to create product: $e',
          backgroundColor: Colors.red.shade100,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
              "Create Product",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 30),

        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                width: 900,
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
                      // Product Name
                      const Text(
                        "Product Name",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter product name',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Formula Name (visible always, required only for Medicine category)
                      StatefulBuilder(
                        builder: (context, _) {
                          final required = _isMedicineCategory;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "Formula Name",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (required)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        'Required for Medicine',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.red.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      'Optional',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _formulaController,
                                validator: (value) {
                                  if (_isMedicineCategory &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Formula name is required for Medicine products';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: required
                                      ? 'e.g. Paracetamol, Amoxicillin…'
                                      : 'Enter formula / generic name (optional)',
                                  filled: true,
                                  fillColor: required
                                      ? Colors.red.shade50
                                      : Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: required
                                        ? BorderSide(color: Colors.red.shade200)
                                        : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: required
                                        ? BorderSide(color: Colors.red.shade300)
                                        : BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        "Description",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter product description';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter product description',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Price & Sale Price Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Price (\$)",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid price';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Sale Price (\$) - Optional",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _salePriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Stock",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _stockController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Category Selection
                      const Text(
                        "Category",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        // Always access the observable so GetX can track it
                        final categories = categoryController.categories
                            .toList();

                        if (categories.isEmpty) {
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

                        return DropdownButtonFormField<String>(
                          initialValue: selectedCategoryId,
                          items: categories
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Text(cat.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategoryId = value;
                              selectedSubcategoryId = null;
                            });
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

                      // Subcategory Selection — filtered by selected category
                      const Text(
                        "Subcategory (Optional)",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        // Always access the observable first so GetX tracks it
                        final allSubs = subcategoryController.subcategories
                            .toList();
                        final categorySubcategories = selectedCategoryId == null
                            ? <dynamic>[]
                            : allSubs
                                  .where(
                                    (sub) =>
                                        sub.categoryId == selectedCategoryId,
                                  )
                                  .toList();

                        if (selectedCategoryId == null) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Select a category first to see its subcategories.',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          );
                        }

                        if (categorySubcategories.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'No subcategories found for this category.',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          );
                        }

                        final validIds = categorySubcategories
                            .map((s) => s.id)
                            .toSet();
                        if (selectedSubcategoryId != null &&
                            !validIds.contains(selectedSubcategoryId)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => selectedSubcategoryId = null);
                            }
                          });
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: validIds.contains(selectedSubcategoryId)
                              ? selectedSubcategoryId
                              : null,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('None'),
                            ),
                            ...categorySubcategories.map(
                              (sub) => DropdownMenuItem(
                                value: sub.id,
                                child: Text(sub.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedSubcategoryId = value;
                            });
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

                      // Brand Selection
                      const Text(
                        "Brand",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        // Always access the observable so GetX can track it
                        final brands = brandController.brands.toList();

                        if (brands.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'No brands available. Please create a brand first.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: selectedBrandId,
                          items: brands
                              .map(
                                (brand) => DropdownMenuItem(
                                  value: brand.id,
                                  child: Text(brand.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedBrandId = value;
                            });
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

                      // Product Image URL
                      const Text(
                        "Product Image URL",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paste a direct image link (https://…). This image will be shown in product cards and the product detail page.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _imageUrlController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/product-image.jpg',
                          prefixIcon: const Icon(Icons.image_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      // Live preview when a URL is entered
                      if (_imageUrlController.text.trim().startsWith('http'))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _imageUrlController.text.trim(),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Invalid image URL',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Featured Toggle (for popular products)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Featured Product",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Will appear in popular products for this category in ecommerce store",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isFeatured,
                              activeThumbColor: Colors.orange,
                              onChanged: (val) {
                                setState(() {
                                  isFeatured = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Status Toggle
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
                              setState(() {
                                isActive = val;
                              });
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

                      // Create Button
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
                          onPressed: isLoading ? null : _createProduct,
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
                                  "Create Product",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
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
