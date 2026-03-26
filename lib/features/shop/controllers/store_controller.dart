import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controls all data for the Store page:
///   • Dynamic category tabs
///   • Featured brands
///   • Products per brand per category
///   • "You might like" per category
class StoreController extends GetxController {
  static StoreController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Observable state ──────────────────────────────────────────────────
  final isLoading = true.obs;

  /// All active categories (used to build tabs dynamically).
  final categories = <Map<String, dynamic>>[].obs;

  /// Brands marked IsFeatured + IsActive in Firestore.
  final featuredBrands = <Map<String, dynamic>>[].obs;

  /// All active brands.
  final allBrands = <Map<String, dynamic>>[].obs;

  /// All active products (fetched once, filtered in-memory per tab).
  final allProducts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchCategories(),
        _fetchBrands(),
        _fetchAllProducts(),
      ]);
    } catch (e) {
      debugPrint('⚠️ StoreController._loadStoreData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Categories ─────────────────────────────────────────────────────────
  Future<void> _fetchCategories() async {
    try {
      final snap = await _db
          .collection('Categories')
          .where('IsActive', isEqualTo: true)
          .get();

      categories.value =
          snap.docs.map((d) {
            final m = d.data();
            return {
              'id': d.id,
              'name': (m['Name'] ?? '').toString(),
              'image': (m['Image'] ?? '').toString(),
            };
          }).toList()..sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );
    } catch (e) {
      debugPrint('⚠️ _fetchCategories: $e');
    }
  }

  // ── Brands ─────────────────────────────────────────────────────────────
  Future<void> _fetchBrands() async {
    try {
      final snap = await _db
          .collection('Brands')
          .where('IsActive', isEqualTo: true)
          .get();

      final brands = snap.docs.map((d) {
        final m = d.data();
        return {
          'id': d.id,
          'name': (m['Name'] ?? '').toString(),
          'image': (m['Image'] ?? '').toString(),
          'isFeatured': m['IsFeatured'] ?? false,
          'productCount': _toInt(m['ProductCount']),
          'categoryIds': List<String>.from(m['CategoryIds'] ?? []),
        };
      }).toList();

      allBrands.value = brands;
      featuredBrands.value = brands
          .where((b) => b['isFeatured'] == true)
          .toList();
    } catch (e) {
      debugPrint('⚠️ _fetchBrands: $e');
    }
  }

  // ── Products ──────────────────────────────────────────────────────────
  Future<void> _fetchAllProducts() async {
    try {
      final snap = await _db
          .collection('Products')
          .where('IsActive', isEqualTo: true)
          .get();

      allProducts.value = snap.docs.map((d) => _productDocToMap(d)).toList();

      // Recompute real product counts per brand from actual products
      _recomputeBrandProductCounts();
    } catch (e) {
      debugPrint('⚠️ _fetchAllProducts: $e');
    }
  }

  /// After products are loaded, count actual products per brand name
  /// and update the allBrands / featuredBrands lists accordingly.
  void _recomputeBrandProductCounts() {
    final Map<String, int> counts = {};
    for (final p in allProducts) {
      final bn = (p['brandName'] as String).toLowerCase();
      counts[bn] = (counts[bn] ?? 0) + 1;
    }
    for (int i = 0; i < allBrands.length; i++) {
      final bn = (allBrands[i]['name'] as String).toLowerCase();
      allBrands[i] = Map<String, dynamic>.from(allBrands[i])
        ..['productCount'] = counts[bn] ?? 0;
    }
    allBrands.refresh();
    featuredBrands.value = allBrands
        .where((b) => b['isFeatured'] == true)
        .toList();
  }

  // ── Derived data helpers ──────────────────────────────────────────────

  /// Returns the top [limit] brands for a category, sorted by total brand rating
  /// (sum of avgRating of all products in that brand within the category).
  List<Map<String, dynamic>> brandsForCategory(
    String categoryId, {
    int limit = 2,
  }) {
    final matching = allBrands
        .where((b) => (b['categoryIds'] as List<String>).contains(categoryId))
        .toList();
    // Sort by total avg rating of products in this category for this brand
    matching.sort((a, b) {
      final aRating = _brandRatingInCategory(a['name'] as String, null);
      final bRating = _brandRatingInCategory(b['name'] as String, null);
      return bRating.compareTo(aRating);
    });
    return matching.take(limit).toList();
  }

  /// Total average rating of all products for a brand (optionally in a category).
  double _brandRatingInCategory(String brandName, String? categoryName) {
    var filtered = allProducts.where(
      (p) =>
          (p['brandName'] as String).toLowerCase() == brandName.toLowerCase(),
    );
    if (categoryName != null && categoryName.isNotEmpty) {
      filtered = filtered.where(
        (p) =>
            (p['categoryName'] as String).toLowerCase() ==
            categoryName.toLowerCase(),
      );
    }
    final list = filtered.toList();
    if (list.isEmpty) return 0.0;
    final totalRating = list.fold<double>(
        0.0, (sum, p) => sum + (p['avgRating'] as double));
    return totalRating / list.length;
  }

  /// Returns products filtered by brandName.
  List<Map<String, dynamic>> productsForBrand(
    String brandName, {
    int limit = 3,
    String? categoryName,
  }) {
    var filtered = allProducts.where(
      (p) =>
          (p['brandName'] as String).toLowerCase() == brandName.toLowerCase(),
    );
    if (categoryName != null && categoryName.isNotEmpty) {
      filtered = filtered.where(
        (p) =>
            (p['categoryName'] as String).toLowerCase() ==
            categoryName.toLowerCase(),
      );
    }
    final list = filtered.toList()
      ..sort(
        (a, b) =>
            (b['avgRating'] as double).compareTo(a['avgRating'] as double),
      );
    return list.take(limit).toList();
  }

  /// Returns top-rated products in a given category.
  List<Map<String, dynamic>> topRatedForCategory(
    String categoryName, {
    int limit = 4,
  }) {
    final filtered =
        allProducts
            .where(
              (p) =>
                  (p['categoryName'] as String).toLowerCase() ==
                  categoryName.toLowerCase(),
            )
            .toList()
          ..sort(
            (a, b) =>
                (b['avgRating'] as double).compareTo(a['avgRating'] as double),
          );
    return filtered.take(limit).toList();
  }

  /// Returns top-rated products globally.
  List<Map<String, dynamic>> topRatedGlobal({int limit = 4}) {
    final sorted = List<Map<String, dynamic>>.from(allProducts)
      ..sort(
        (a, b) =>
            (b['avgRating'] as double).compareTo(a['avgRating'] as double),
      );
    return sorted.take(limit).toList();
  }

  /// Featured products in a category (IsFeatured toggled on in admin).
  List<Map<String, dynamic>> featuredForCategory(String categoryName,
      {int limit = 50}) {
    return allProducts
        .where((p) =>
            p['isFeatured'] == true &&
            (p['categoryName'] as String).toLowerCase() ==
                categoryName.toLowerCase())
        .toList()
      ..sort((a, b) =>
          (b['avgRating'] as double).compareTo(a['avgRating'] as double));
  }

  /// Featured products globally.
  List<Map<String, dynamic>> featuredGlobal({int limit = 50}) {
    return allProducts
        .where((p) => p['isFeatured'] == true)
        .toList()
      ..sort((a, b) =>
          (b['avgRating'] as double).compareTo(a['avgRating'] as double));
  }

  /// Returns all products for a given brand (optionally filtered by category).
  List<Map<String, dynamic>> allProductsForBrand(
    String brandName, {
    String? categoryName,
  }) {
    var filtered = allProducts.where(
      (p) =>
          (p['brandName'] as String).toLowerCase() == brandName.toLowerCase(),
    );
    if (categoryName != null && categoryName.isNotEmpty) {
      filtered = filtered.where(
        (p) =>
            (p['categoryName'] as String).toLowerCase() ==
            categoryName.toLowerCase(),
      );
    }
    return filtered.toList();
  }

  /// Top brands globally, sorted by total brand rating across all products.
  List<Map<String, dynamic>> topBrandsGlobal({int limit = 2}) {
    final sorted = List<Map<String, dynamic>>.from(allBrands)
      ..sort((a, b) {
        final aRating = _brandRatingInCategory(a['name'] as String, null);
        final bRating = _brandRatingInCategory(b['name'] as String, null);
        return bRating.compareTo(aRating);
      });
    return sorted.take(limit).toList();
  }

  // ── Search: products + brands ─────────────────────────────────────────
  final searchResults = <Map<String, dynamic>>[].obs;
  final brandSearchResults = <Map<String, dynamic>>[].obs;
  final isSearching = false.obs;

  void searchStore(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      searchResults.clear();
      brandSearchResults.clear();
      return;
    }
    isSearching.value = true;

    // Products
    searchResults.value = allProducts.where((p) {
      final blob = '${p['name']} ${p['brandName']} ${p['categoryName']}'
          .toLowerCase();
      return blob.contains(q);
    }).toList();

    // Brands
    brandSearchResults.value = allBrands.where((b) {
      return (b['name'] as String).toLowerCase().contains(q);
    }).toList();

    isSearching.value = false;
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  static Map<String, dynamic> _productDocToMap(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final m = d.data();
    final imgs = (m['Images'] is List)
        ? List<String>.from((m['Images'] as List).map((e) => e.toString()))
        : <String>[];
    return {
      'id': d.id,
      'name': (m['Name'] ?? '').toString(),
      'brandName': (m['BrandName'] ?? '').toString(),
      'categoryName': (m['CategoryName'] ?? '').toString(),
      'subcategoryName': (m['SubcategoryName'] ?? '').toString(),
      'description': (m['Description'] ?? '').toString(),
      'price': _toDouble(m['Price']),
      'salePrice': _toDouble(m['SalePrice']),
      'image': imgs.isNotEmpty ? imgs.first : '',
      'images': imgs,
      'stock': _toInt(m['Stock']),
      'avgRating': _toDouble(m['avgRating']),
      'reviewCount': _toInt(m['reviewCount']),
      'isFeatured': m['IsFeatured'] ?? false,
    };
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
