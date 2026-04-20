import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/banner_model.dart';

class BannerController extends GetxController {
  static BannerController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<BannerModel> banners = <BannerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Filtered list for the UI table
  List<BannerModel> get filteredBanners {
    if (searchQuery.value.isEmpty) return banners;
    final q = searchQuery.value.toLowerCase();
    return banners
        .where(
          (b) =>
              b.title.toLowerCase().contains(q) ||
              b.description.toLowerCase().contains(q) ||
              b.redirect.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchBanners();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;
      final snapshot = await _db
          .collection('Banners')
          .orderBy('CreatedAt', descending: true)
          .get();
      banners.value = snapshot.docs
          .map((d) => BannerModel.fromSnapshot(d))
          .toList();
    } catch (e) {
      Get.snackbar(
        'Info',
        'No banners found. Create a new banner to get started.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      banners.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────
  Future<void> createBanner(BannerModel banner) async {
    try {
      isLoading.value = true;
      final docRef = await _db.collection('Banners').add(banner.toJson());
      banners.insert(0, banner.copyWith(id: docRef.id));
      Get.snackbar(
        'Success',
        'Banner created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create banner: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────
  Future<void> updateBanner(BannerModel banner) async {
    try {
      isLoading.value = true;
      final updated = banner.copyWith(updatedAt: DateTime.now());
      await _db.collection('Banners').doc(banner.id).update(updated.toJson());

      final idx = banners.indexWhere((b) => b.id == banner.id);
      if (idx != -1) banners[idx] = updated;

      Get.snackbar(
        'Success',
        'Banner updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update banner: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> deleteBanner(String bannerId) async {
    try {
      await _db.collection('Banners').doc(bannerId).delete();
      banners.removeWhere((b) => b.id == bannerId);
      Get.snackbar(
        'Success',
        'Banner deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete banner: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── Toggle Active ─────────────────────────────────────────────────────────
  Future<void> toggleActive(BannerModel banner) async {
    await updateBanner(banner.copyWith(isActive: !banner.isActive));
  }
}
