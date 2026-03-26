import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

/// Fetches subcategories and their products for a given parent category.
///
/// Firestore layout (matches Admin panel models):
///   Categories/{categoryId}          — field: Name, Image, IsFeatured, IsActive
///   Subcategories/{subId}            — field: CategoryId, Name, Image, IsActive
///   Products/{productId}             — field: SubcategoryId, CategoryId, IsActive
class SubCategoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// List of subcategory maps:
  ///   { id, name, image, products: [ {id, name, brandName, price, salePrice, image} ] }
  final subCategories = <Map<String, dynamic>>[].obs;

  // ── public API ────────────────────────────────────────────────────────────

  /// Safely convert any Firestore value to double
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  /// Safely convert any Firestore value to int
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Call this once with the parent category id to load all data.
  Future<void> loadSubCategories(String categoryId) async {
    if (categoryId.isEmpty) return;
    isLoading.value = true;
    errorMessage.value = '';
    subCategories.clear();

    try {
      // ── Step 1: fetch all active subcategories for this category ──────────
      // Collection is 'Subcategories' (capital S, lowercase c)
      // Link field is 'CategoryId'
      final subSnap = await _db
          .collection('Subcategories')
          .where('CategoryId', isEqualTo: categoryId)
          .where('IsActive', isEqualTo: true)
          .get();

      if (subSnap.docs.isEmpty) {
        isLoading.value = false;
        return;
      }

      // ── Step 2: for every subcategory fetch its active products in parallel ─
      final List<Map<String, dynamic>> results = [];

      await Future.wait(
        subSnap.docs.map((subDoc) async {
          final subData = subDoc.data();
          final subId = subDoc.id;
          final subName = (subData['Name'] ?? '').toString();
          final subImage = (subData['Image'] ?? '').toString();

          final prodSnap = await _db
              .collection('Products')
              .where('SubcategoryId', isEqualTo: subId)
              .where('IsActive', isEqualTo: true)
              .get();

          final products = prodSnap.docs.map((pDoc) {
            final p = pDoc.data();
            final imgs = (p['Images'] is List)
                ? List<String>.from(
                    (p['Images'] as List).map((e) => e.toString()),
                  )
                : <String>[];
            return <String, dynamic>{
              'id': pDoc.id,
              'name': (p['Name'] ?? '').toString(),
              'brandName': (p['BrandName'] ?? '').toString(),
              'categoryName': (p['CategoryName'] ?? '').toString(),
              'description': (p['Description'] ?? '').toString(),
              'price': _toDouble(p['Price']),
              'salePrice': _toDouble(p['SalePrice']),
              'image': imgs.isNotEmpty ? imgs.first : '',
              'images': imgs,
              'stock': _toInt(p['Stock']),
              'avgRating': _toDouble(p['avgRating']),
              'reviewCount': _toInt(p['reviewCount']),
              'subcategoryId': subId,
              'subcategoryName': subName,
            };
          }).toList();

          // Include subcategory even if it has no products
          results.add({
            'id': subId,
            'name': subName,
            'image': subImage,
            'products': products,
          });
        }),
      );

      // Sort alphabetically for consistent ordering
      results.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );

      subCategories.value = results;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
