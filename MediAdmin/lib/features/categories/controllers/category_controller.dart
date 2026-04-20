import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/category_model.dart';

class CategoryController extends GetxController {
  static CategoryController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool hasInitialized = false.obs;

  // Initialize data (call this when needed)
  Future<void> initialize() async {
    if (!hasInitialized.value) {
      await fetchCategories();
      hasInitialized.value = true;
    }
  }

  // Get filtered categories based on search
  List<CategoryModel> get filteredCategories {
    if (searchQuery.value.isEmpty) {
      return categories;
    }
    return categories.where((category) {
      return category.name.toLowerCase().contains(
        searchQuery.value.toLowerCase(),
      );
    }).toList();
  }

  // Fetch all categories
  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final snapshot = await _db
          .collection('Categories')
          .orderBy('CreatedAt', descending: true)
          .get();
      categories.value = snapshot.docs
          .map((doc) => CategoryModel.fromSnapshot(doc))
          .toList();
      print('✅ Successfully fetched ${categories.length} categories');
    } catch (e) {
      // Show error message to help with debugging
      print('❌ Failed to fetch categories: $e');
      categories.value = []; // Set empty list on error
      Get.snackbar(
        'Info',
        'No categories found. You can create a new category.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Create new category
  Future<void> createCategory(CategoryModel category) async {
    try {
      isLoading.value = true;
      final docRef = await _db.collection('Categories').add(category.toJson());

      // Add to local list
      categories.insert(0, category.copyWith(id: docRef.id));

      Get.snackbar(
        'Success',
        'Category created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create category: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _db
          .collection('Categories')
          .doc(category.id)
          .update(category.copyWith(updatedAt: DateTime.now()).toJson());

      // Update local list
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = category.copyWith(updatedAt: DateTime.now());
      }

      Get.snackbar(
        'Success',
        'Category updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update category: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Toggle featured status
  Future<void> toggleFeatured(String categoryId, bool isFeatured) async {
    try {
      await _db.collection('Categories').doc(categoryId).update({
        'IsFeatured': isFeatured,
        'UpdatedAt': Timestamp.now(),
      });

      // Update local list
      final index = categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        categories[index] = categories[index].copyWith(
          isFeatured: isFeatured,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update featured status: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Toggle active status
  Future<void> toggleActive(String categoryId, bool isActive) async {
    try {
      await _db.collection('Categories').doc(categoryId).update({
        'IsActive': isActive,
        'UpdatedAt': Timestamp.now(),
      });

      // Update local list
      final index = categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        categories[index] = categories[index].copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update status: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _db.collection('Categories').doc(categoryId).delete();

      // Remove from local list
      categories.removeWhere((c) => c.id == categoryId);

      Get.snackbar(
        'Success',
        'Category deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete category: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
