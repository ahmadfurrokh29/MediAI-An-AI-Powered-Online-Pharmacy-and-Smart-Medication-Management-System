import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../categories/controllers/category_controller.dart';
import '../../subcategories/controllers/subcategory_controller.dart';
import '../../brands/controllers/brand_controller.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

class UpdateProductPage extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic> product;

  const UpdateProductPage({
    super.key,
    required this.onBack,
    required this.product,
  });

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _formulaController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;

  late bool isFeatured;
  late bool isRecommended;
  late bool isActive;
  bool isLoading = false;

  late String? selectedCategoryId;
  late String? selectedSubcategoryId;
  late String? selectedBrandId;

  final categoryController = Get.find<CategoryController>();
  final subcategoryController = Get.find<SubcategoryController>();
  final brandController = Get.find<BrandController>();
  final productController = Get.find<ProductController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name']);
    _formulaController = TextEditingController(
      text: widget.product['formulaName'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product['description'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product['price']?.toString() ?? '',
    );
    _salePriceController = TextEditingController(
      text: widget.product['salePrice']?.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product['stock']?.toString() ?? '',
    );
    final images = widget.product['images'] as List<dynamic>? ?? [];
    _imageUrlController = TextEditingController(
      text: images.isNotEmpty ? images.first : '',
    );

    isFeatured = widget.product['isFeatured'] ?? false;
    isRecommended = widget.product['isRecommended'] ?? false;
    isActive = widget.product['isActive'] ?? true;
    selectedCategoryId = widget.product['categoryId'];
    selectedSubcategoryId = widget.product['subcategoryId'];
    selectedBrandId = widget.product['brandId'];

    if (selectedCategoryId != null && selectedCategoryId!.isEmpty) {
      selectedCategoryId = null;
    }
    if (selectedSubcategoryId != null && selectedSubcategoryId!.isEmpty) {
      selectedSubcategoryId = null;
    }
    if (selectedBrandId != null && selectedBrandId!.isEmpty) {
      selectedBrandId = null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      categoryController.initialize();
      subcategoryController.initialize();
      brandController.initialize();
    });
  }

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

  Future<void> _handleUpdate() async {
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

    setState(() => isLoading = true);

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

      final updated = ProductModel(
        id: widget.product['id'],
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
            : (widget.product['images'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [],
        categoryId: selectedCategoryId!,
        categoryName: category.name,
        subcategoryId: selectedSubcategoryId ?? '',
        subcategoryName: subcategoryName,
        brandId: selectedBrandId!,
        brandName: brand.name,
        isFeatured: isFeatured,
        isRecommended: isRecommended,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await productController.updateProduct(updated);
      await productController.fetchProducts();
      if (mounted) widget.onBack();
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to update product: $e',
          backgroundColor: Colors.red.shade100,
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
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
              "Update Product",
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

                      // Formula Name
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

                      // Price, Sale Price, Stock
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
                                    if (value == null || value.isEmpty)
                                      return 'Required';
                                    if (double.tryParse(value) == null)
                                      return 'Invalid price';
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
                                    if (value == null || value.isEmpty)
                                      return 'Required';
                                    if (int.tryParse(value) == null)
                                      return 'Invalid';
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

                      // Category
                      const Text(
                        "Category",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
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
                          value: selectedCategoryId,
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

                      // Subcategory
                      const Text(
                        "Subcategory (Optional)",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        // Access observable to register dependency
                        subcategoryController.subcategories.length;
                        final subs = filteredSubcategories;
                        if (subs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              selectedCategoryId == null
                                  ? 'Select a category first'
                                  : 'No subcategories for this category',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          value: selectedSubcategoryId,
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('None'),
                            ),
                            ...subs.map(
                              (sub) => DropdownMenuItem(
                                value: sub.id,
                                child: Text(sub.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => selectedSubcategoryId = value);
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

                      // Brand
                      const Text(
                        "Brand",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
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
                          value: selectedBrandId,
                          items: brands
                              .map(
                                (b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text(b.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedBrandId = value);
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

                      // Image URL
                      const Text(
                        "Image URL (Optional)",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/image.png',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Toggles
                      Row(
                        children: [
                          const Text(
                            "Featured",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 20),
                          Switch(
                            value: isFeatured,
                            activeThumbColor: Colors.green,
                            onChanged: (val) =>
                                setState(() => isFeatured = val),
                          ),
                          const SizedBox(width: 30),
                          const Text(
                            "Active",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 20),
                          Switch(
                            value: isActive,
                            activeThumbColor: Colors.green,
                            onChanged: (val) => setState(() => isActive = val),
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

                      // Update Button
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
