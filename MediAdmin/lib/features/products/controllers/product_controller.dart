import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';

class ProductController extends GetxController {
  static ProductController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategoryFilter = ''.obs;
  final RxString selectedBrandFilter = ''.obs;
  final RxBool hasInitialized = false.obs;

  // Recommended products page filters
  final RxString recommendedSearchQuery = ''.obs;
  final RxString recommendedCategoryFilter = ''.obs;

  // Initialize data (call this when needed)
  Future<void> initialize() async {
    if (!hasInitialized.value) {
      await fetchProducts();
      hasInitialized.value = true;
    }
  }

  // Get filtered products
  List<ProductModel> get filteredProducts {
    var filtered = products.toList();

    // Search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            product.categoryName.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            product.brandName.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            );
      }).toList();
    }

    // Category filter
    if (selectedCategoryFilter.value.isNotEmpty) {
      filtered = filtered
          .where(
            (product) => product.categoryId == selectedCategoryFilter.value,
          )
          .toList();
    }

    // Brand filter
    if (selectedBrandFilter.value.isNotEmpty) {
      filtered = filtered
          .where((product) => product.brandId == selectedBrandFilter.value)
          .toList();
    }

    return filtered;
  }

  // Get all recommended products (for the recommended products page)
  List<ProductModel> get recommendedFilteredProducts {
    var filtered = products.toList();

    // Search filter
    if (recommendedSearchQuery.value.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(
              recommendedSearchQuery.value.toLowerCase(),
            ) ||
            product.categoryName.toLowerCase().contains(
              recommendedSearchQuery.value.toLowerCase(),
            ) ||
            product.subcategoryName.toLowerCase().contains(
              recommendedSearchQuery.value.toLowerCase(),
            );
      }).toList();
    }

    // Category filter for recommended page
    if (recommendedCategoryFilter.value.isNotEmpty) {
      filtered = filtered
          .where(
            (product) => product.categoryId == recommendedCategoryFilter.value,
          )
          .toList();
    }

    return filtered;
  }

  // Count of currently recommended products
  int get recommendedCount => products.where((p) => p.isRecommended).length;

  // Fetch all products
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final snapshot = await _db
          .collection('Products')
          .orderBy('CreatedAt', descending: true)
          .get();
      products.value = snapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();
      print('✅ Successfully fetched ${products.length} products');
    } catch (e) {
      // Show error message to help with debugging
      print('❌ Failed to fetch products: $e');
      products.value = []; // Set empty list on error
      Get.snackbar(
        'Info',
        'No products found. You can create a new product.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get products by category (for ecommerce store)
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final snapshot = await _db
          .collection('Products')
          .where('CategoryId', isEqualTo: categoryId)
          .where('IsActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch products: $e');
      return [];
    }
  }

  // Get featured products by category (popular products for ecommerce)
  Future<List<ProductModel>> getFeaturedProductsByCategory(
    String categoryId,
  ) async {
    try {
      final snapshot = await _db
          .collection('Products')
          .where('CategoryId', isEqualTo: categoryId)
          .where('IsFeatured', isEqualTo: true)
          .where('IsActive', isEqualTo: true)
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch featured products: $e');
      return [];
    }
  }

  // Get products by brand (for ecommerce store)
  Future<List<ProductModel>> getProductsByBrand(String brandId) async {
    try {
      final snapshot = await _db
          .collection('Products')
          .where('BrandId', isEqualTo: brandId)
          .where('IsActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch products: $e');
      return [];
    }
  }

  // Create new product
  Future<void> createProduct(ProductModel product) async {
    try {
      isLoading.value = true;
      final docRef = await _db.collection('Products').add(product.toJson());

      products.insert(0, product.copyWith(id: docRef.id));

      Get.snackbar(
        'Success',
        'Product created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create product: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _db
          .collection('Products')
          .doc(product.id)
          .update(product.copyWith(updatedAt: DateTime.now()).toJson());

      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        products[index] = product.copyWith(updatedAt: DateTime.now());
      }

      Get.snackbar(
        'Success',
        'Product updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update product: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Toggle featured status (for popular products)
  Future<void> toggleFeatured(String productId, bool value) async {
    try {
      await _db.collection('Products').doc(productId).update({
        'IsFeatured': value,
        'UpdatedAt': DateTime.now(),
      });

      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        products[index] = products[index].copyWith(
          isFeatured: value,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update featured status: $e');
    }
  }

  // Toggle recommended status (per-category recommended products)
  Future<void> toggleRecommended(String productId, bool value) async {
    try {
      await _db.collection('Products').doc(productId).update({
        'IsRecommended': value,
        'UpdatedAt': DateTime.now(),
      });

      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        products[index] = products[index].copyWith(
          isRecommended: value,
          updatedAt: DateTime.now(),
        );
        products.refresh();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update recommended status: $e');
    }
  }

  // Toggle active status
  Future<void> toggleActive(String productId, bool value) async {
    try {
      await _db.collection('Products').doc(productId).update({
        'IsActive': value,
        'UpdatedAt': DateTime.now(),
      });

      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        products[index] = products[index].copyWith(
          isActive: value,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update active status: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('Products').doc(productId).delete();
      products.removeWhere((product) => product.id == productId);

      Get.snackbar(
        'Success',
        'Product deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete product: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Clear filters
  void clearFilters() {
    selectedCategoryFilter.value = '';
    selectedBrandFilter.value = '';
    searchQuery.value = '';
  }

  // Clear recommended page filters
  void clearRecommendedFilters() {
    recommendedSearchQuery.value = '';
    recommendedCategoryFilter.value = '';
  }
}
