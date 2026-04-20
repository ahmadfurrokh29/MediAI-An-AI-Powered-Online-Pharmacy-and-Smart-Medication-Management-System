import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/brand_model.dart';

class BrandController extends GetxController {
  static BrandController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<BrandModel> brands = <BrandModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool hasInitialized = false.obs;

  // Initialize data (call this when needed)
  Future<void> initialize() async {
    if (!hasInitialized.value) {
      await fetchBrands();
      hasInitialized.value = true;
    }
  }

  // Get filtered brands
  List<BrandModel> get filteredBrands {
    if (searchQuery.value.isEmpty) {
      return brands;
    }
    return brands.where((brand) {
      return brand.name.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  // Fetch all brands
  Future<void> fetchBrands() async {
    try {
      isLoading.value = true;
      final snapshot = await _db
          .collection('Brands')
          .orderBy('CreatedAt', descending: true)
          .get();
      brands.value = snapshot.docs
          .map((doc) => BrandModel.fromSnapshot(doc))
          .toList();
      print('✅ Successfully fetched ${brands.length} brands');
    } catch (e) {
      // Show error message to help with debugging
      print('❌ Failed to fetch brands: $e');
      brands.value = []; // Set empty list on error
      Get.snackbar(
        'Info',
        'No brands found. You can create a new brand.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Create new brand
  Future<void> createBrand(BrandModel brand) async {
    try {
      isLoading.value = true;
      final docRef = await _db.collection('Brands').add(brand.toJson());

      brands.insert(0, brand.copyWith(id: docRef.id));

      Get.snackbar(
        'Success',
        'Brand created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create brand: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update brand
  Future<void> updateBrand(BrandModel brand) async {
    try {
      await _db
          .collection('Brands')
          .doc(brand.id)
          .update(brand.copyWith(updatedAt: DateTime.now()).toJson());

      final index = brands.indexWhere((b) => b.id == brand.id);
      if (index != -1) {
        brands[index] = brand.copyWith(updatedAt: DateTime.now());
      }

      Get.snackbar(
        'Success',
        'Brand updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update brand: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Toggle featured
  Future<void> toggleFeatured(String brandId, bool isFeatured) async {
    try {
      await _db.collection('Brands').doc(brandId).update({
        'IsFeatured': isFeatured,
        'UpdatedAt': Timestamp.now(),
      });

      final index = brands.indexWhere((b) => b.id == brandId);
      if (index != -1) {
        brands[index] = brands[index].copyWith(
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
  Future<void> toggleActive(String brandId, bool isActive) async {
    try {
      await _db.collection('Brands').doc(brandId).update({
        'IsActive': isActive,
        'UpdatedAt': Timestamp.now(),
      });

      final index = brands.indexWhere((b) => b.id == brandId);
      if (index != -1) {
        brands[index] = brands[index].copyWith(
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

  // Delete brand
  Future<void> deleteBrand(String brandId) async {
    try {
      await _db.collection('Brands').doc(brandId).delete();
      brands.removeWhere((b) => b.id == brandId);

      Get.snackbar(
        'Success',
        'Brand deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete brand: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
