import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/coupon_model.dart';

class CouponController extends GetxController {
  static CouponController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<CouponModel> coupons = <CouponModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool hasInitialized = false.obs;

  Future<void> initialize() async {
    if (!hasInitialized.value) {
      await fetchCoupons();
      hasInitialized.value = true;
    }
  }

  List<CouponModel> get filteredCoupons {
    if (searchQuery.value.isEmpty) return coupons;
    final q = searchQuery.value.toLowerCase();
    return coupons.where((c) =>
        c.code.toLowerCase().contains(q) ||
        c.description.toLowerCase().contains(q) ||
        c.type.toLowerCase().contains(q)).toList();
  }

  Future<void> fetchCoupons() async {
    try {
      isLoading.value = true;
      final snapshot = await _db
          .collection('Coupons')
          .orderBy('CreatedAt', descending: true)
          .get();
      coupons.value = snapshot.docs
          .map((doc) => CouponModel.fromSnapshot(doc))
          .toList();
      print('✅ Fetched ${coupons.length} coupons');
    } catch (e) {
      print('❌ Failed to fetch coupons: $e');
      coupons.value = [];
      Get.snackbar('Info', 'No coupons found. Create a new coupon.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createCoupon(CouponModel coupon) async {
    try {
      isLoading.value = true;
      final docRef = await _db.collection('Coupons').add(coupon.toJson());
      coupons.insert(0, coupon.copyWith(id: docRef.id));
      Get.snackbar('Success', 'Coupon created successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to create coupon: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCoupon(CouponModel coupon) async {
    try {
      isLoading.value = true;
      await _db
          .collection('Coupons')
          .doc(coupon.id)
          .update(coupon.copyWith(updatedAt: DateTime.now()).toJson());
      final index = coupons.indexWhere((c) => c.id == coupon.id);
      if (index != -1) {
        coupons[index] = coupon.copyWith(updatedAt: DateTime.now());
      }
      Get.snackbar('Success', 'Coupon updated successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update coupon: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleActive(String couponId, bool isActive) async {
    try {
      await _db.collection('Coupons').doc(couponId).update({
        'IsActive': isActive,
        'UpdatedAt': Timestamp.now(),
      });
      final index = coupons.indexWhere((c) => c.id == couponId);
      if (index != -1) {
        coupons[index] = coupons[index].copyWith(isActive: isActive);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteCoupon(String couponId) async {
    try {
      await _db.collection('Coupons').doc(couponId).delete();
      coupons.removeWhere((c) => c.id == couponId);
      Get.snackbar('Success', 'Coupon deleted successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete coupon: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
