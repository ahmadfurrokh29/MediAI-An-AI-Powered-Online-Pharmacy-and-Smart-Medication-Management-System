import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/cloudinary_service.dart';
import '../widgets/product_image_upload_widget.dart';
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

  /// Product images: pre-filled from existing URLs + any newly uploaded.
  final List<ProductImageEntry> _images = [];

  late bool isFeatured;
  late bool isRecommended;
  late bool isActive;
  bool isPrescribed = false;
  String? selectedMedicineForm;
  late final TextEditingController _tabletsInPackController;
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

    // Pre-populate images from existing Firestore data
    final existingImages = widget.product['images'] as List<dynamic>? ?? [];
    final existingPublicIds = widget.product['imagePublicIds'] as List<dynamic>? ?? [];
    for (var i = 0; i < existingImages.length; i++) {
      final s = existingImages[i].toString().trim();
      if (s.isNotEmpty) {
        final pid = i < existingPublicIds.length ? existingPublicIds[i].toString() : null;
        _images.add(ProductImageEntry(name: s.split('/').last, url: s, publicId: pid));
      }
    }

    isFeatured = widget.product['isFeatured'] ?? false;
    isRecommended = widget.product['isRecommended'] ?? false;
    isActive = widget.product['isActive'] ?? true;
    isPrescribed = widget.product['isPrescribed'] ?? false;
    final formVal = (widget.product['medicineForm'] ?? '').toString();
    selectedMedicineForm = formVal.isEmpty ? null : formVal;
    _tabletsInPackController = TextEditingController(
      text: (widget.product['tabletsInPack'] ?? 0) == 0
          ? ''
          : widget.product['tabletsInPack'].toString(),
    );
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
    _tabletsInPackController.dispose();
    super.dispose();
  }

  /// Open browser file picker and upload selected images to Cloudinary.
  Future<void> _pickAndUploadImages() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/png,image/jpeg,image/jpg,image/webp'
      ..multiple = true;

    html.document.body!.append(input);

    final completer = Completer<List<html.File>?>();
    input.onChange.listen((_) {
      final files = input.files;
      if (!completer.isCompleted) {
        completer.complete(
          (files != null && files.isNotEmpty) ? files : null,
        );
      }
    });
    input.click();

    final files = await completer.future;
    input.remove();
    if (files == null) return;

    for (final htmlFile in files) {
      final readerCompleter = Completer<String>();
      final reader = html.FileReader();
      reader.onLoad.listen((_) {
        if (!readerCompleter.isCompleted) {
          readerCompleter.complete(reader.result as String);
        }
      });
      reader.onError.listen((_) {
        if (!readerCompleter.isCompleted) {
          readerCompleter.completeError('FileReader error');
        }
      });
      reader.readAsDataUrl(htmlFile);

      final dataUrl = await readerCompleter.future;
      final bytes = base64Decode(dataUrl.split(',').last);

      final entry = ProductImageEntry(
        bytes: bytes,
        name: htmlFile.name,
        uploading: true,
      );
      if (mounted) setState(() => _images.add(entry));

      try {
        final result = await CloudinaryService.uploadImage(
          bytes: bytes,
          fileName: htmlFile.name,
          folder: 'products',
        );
        if (mounted) {
          setState(() {
            entry.url = result.url;
            entry.publicId = result.publicId;
            entry.uploading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _images.remove(entry));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed for ${htmlFile.name}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
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
        images: _images.where((e) => e.url != null).map((e) => e.url!).toList(),
        imagePublicIds: _images.where((e) => e.publicId != null).map((e) => e.publicId!).toList(),
        categoryId: selectedCategoryId!,
        categoryName: category.name,
        subcategoryId: selectedSubcategoryId ?? '',
        subcategoryName: subcategoryName,
        brandId: selectedBrandId!,
        brandName: brand.name,
        isFeatured: isFeatured,
        isRecommended: isRecommended,
        isActive: isActive,
        isPrescribed: isPrescribed,
        medicineForm: selectedMedicineForm ?? '',
        tabletsInPack: int.tryParse(_tabletsInPackController.text.trim()) ?? 0,
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

                      // --- Prescribed ---
                      Row(
                        children: [
                          const Text(
                            'Prescribed',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Optional',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: isPrescribed,
                            activeColor: Colors.blue,
                            onChanged: (val) =>
                                setState(() => isPrescribed = val),
                          ),
                          Text(
                            isPrescribed ? 'Yes' : 'No',
                            style: TextStyle(
                              color: isPrescribed
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // --- Medicine Form ---
                      Row(
                        children: [
                          const Text(
                            'Medicine Form',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
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
                      DropdownButtonFormField<String>(
                        value: selectedMedicineForm,
                        decoration: InputDecoration(
                          hintText: 'Select form (e.g. Tablets)',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Tablets', child: Text('Tablets')),
                          DropdownMenuItem(
                              value: 'Syrup', child: Text('Syrup')),
                          DropdownMenuItem(
                              value: 'Drops', child: Text('Drops')),
                          DropdownMenuItem(
                              value: 'Capsules', child: Text('Capsules')),
                          DropdownMenuItem(
                              value: 'Cream', child: Text('Cream')),
                          DropdownMenuItem(
                              value: 'Injection', child: Text('Injection')),
                        ],
                        onChanged: (val) =>
                            setState(() => selectedMedicineForm = val),
                      ),

                      // --- Tablets/Capsules in Pack ---
                      if (selectedMedicineForm == 'Tablets' ||
                          selectedMedicineForm == 'Capsules') ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              '${selectedMedicineForm} in Pack',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
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
                          controller: _tabletsInPackController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'e.g. 10, 20, 30',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],

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

                      // ── Product Images Upload ────────────────────────
                      Row(
                        children: [
                          const Text(
                            'Product Images',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(PNG, JPG, JPEG, WebP — up to 5)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Uploaded image grid
                      if (_images.isNotEmpty)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (int i = 0; i < _images.length; i++)
                              ProductImageThumbnail(
                                image: _images[i],
                                onRemove: () => _removeImage(i),
                                isPrimary: i == 0,
                              ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      if (_images.length < 5)
                        OutlinedButton.icon(
                          onPressed: _pickAndUploadImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            _images.isEmpty
                                ? 'Upload Product Images'
                                : 'Add More Images',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      if (_images.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'First image will be the main thumbnail.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
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
