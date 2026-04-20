import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/subcategory_model.dart';

class SubcategoryController extends GetxController {
  static SubcategoryController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<SubcategoryModel> subcategories = <SubcategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool hasInitialized = false.obs;

  // Initialize data (call this when needed)
  Future<void> initialize() async {
    if (!hasInitialized.value) {
      await fetchSubcategories();
      hasInitialized.value = true;
    }
  }

  // Get filtered subcategories
  List<SubcategoryModel> get filteredSubcategories {
    if (searchQuery.value.isEmpty) {
      return subcategories;
    }
    return subcategories.where((sub) {
      return sub.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          sub.categoryName.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );
    }).toList();
  }

  // Fetch all subcategories
  Future<void> fetchSubcategories() async {
    try {
      isLoading.value = true;
      final snapshot = await _db
          .collection('Subcategories')
          .orderBy('CreatedAt', descending: true)
          .get();
      subcategories.value = snapshot.docs
          .map((doc) => SubcategoryModel.fromSnapshot(doc))
          .toList();
      print('✅ Successfully fetched ${subcategories.length} subcategories');
    } catch (e) {
      // Show error message to help with debugging
      print('❌ Failed to fetch subcategories: $e');
      subcategories.value = []; // Set empty list on error
      Get.snackbar(
        'Info',
        'No subcategories found. You can create a new subcategory.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Create new subcategory
  Future<void> createSubcategory(SubcategoryModel subcategory) async {
    try {
      isLoading.value = true;
      final docRef = await _db
          .collection('Subcategories')
          .add(subcategory.toJson());

      subcategories.insert(0, subcategory.copyWith(id: docRef.id));

      Get.snackbar(
        'Success',
        'Subcategory created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create subcategory: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update subcategory
  Future<void> updateSubcategory(SubcategoryModel subcategory) async {
    try {
      await _db
          .collection('Subcategories')
          .doc(subcategory.id)
          .update(subcategory.copyWith(updatedAt: DateTime.now()).toJson());

      final index = subcategories.indexWhere((s) => s.id == subcategory.id);
      if (index != -1) {
        subcategories[index] = subcategory.copyWith(updatedAt: DateTime.now());
      }

      Get.snackbar(
        'Success',
        'Subcategory updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update subcategory: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Toggle featured
  Future<void> toggleFeatured(String subcategoryId, bool isFeatured) async {
    try {
      await _db.collection('Subcategories').doc(subcategoryId).update({
        'IsFeatured': isFeatured,
        'UpdatedAt': Timestamp.now(),
      });

      final index = subcategories.indexWhere((s) => s.id == subcategoryId);
      if (index != -1) {
        subcategories[index] = subcategories[index].copyWith(
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

  // Toggle active
  Future<void> toggleActive(String subcategoryId, bool isActive) async {
    try {
      await _db.collection('Subcategories').doc(subcategoryId).update({
        'IsActive': isActive,
        'UpdatedAt': Timestamp.now(),
      });

      final index = subcategories.indexWhere((s) => s.id == subcategoryId);
      if (index != -1) {
        subcategories[index] = subcategories[index].copyWith(
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

  // Delete subcategory
  Future<void> deleteSubcategory(String subcategoryId) async {
    try {
      await _db.collection('Subcategories').doc(subcategoryId).delete();
      subcategories.removeWhere((s) => s.id == subcategoryId);

      Get.snackbar(
        'Success',
        'Subcategory deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete subcategory: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
