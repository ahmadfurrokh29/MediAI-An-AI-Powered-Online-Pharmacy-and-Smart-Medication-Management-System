import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  static HomeController get instance => Get.find<HomeController>();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------- UI state ----------
  final carouselCurrentIndex = 0.obs;
  final isLoading = false.obs;

  // ---------- Req #1: User name ----------
  final userName = ''.obs;

  // ---------- Req #3: Featured categories ----------
  final featuredCategories = <Map<String, dynamic>>[].obs;

  // ---------- Req #4: Active banners ----------
  final activeBanners = <Map<String, dynamic>>[].obs;

  // ---------- Req #5: Recommended products ----------
  final recommendedProducts = <Map<String, dynamic>>[].obs;

  // ---------- Req #2: Search ----------
  final searchResults = <Map<String, dynamic>>[].obs;
  final isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Wait for Firebase Auth to restore its persisted session, then load data.
    // authStateChanges emits once immediately (null if signed out, User if signed in).
    _auth.authStateChanges().first.then((_) => _loadHomeData());
  }

  void updatePageIndicator(int index) {
    carouselCurrentIndex.value = index;
  }

  Future<void> _loadHomeData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchUserName(),
        _fetchFeaturedCategories(),
        _fetchActiveBanners(),
        _fetchRecommendedProducts(),
      ]);
    } catch (e) {
      debugPrint('⚠️ _loadHomeData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Public method so the home screen can trigger a manual refresh
  Future<void> reloadHomeData() => _loadHomeData();

  // ── Req #1 ────────────────────────────────────────────────────────────────
  Future<void> _fetchUserName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        userName.value = 'Guest';
        return;
      }

      // Try Firestore Users document first (set during email signup)
      final doc = await _db.collection('Users').doc(user.uid).get();
      if (doc.exists) {
        final d = doc.data()!;
        final first = (d['FirstName'] ?? '').toString().trim();
        final last = (d['LastName'] ?? '').toString().trim();
        final full = '$first $last'.trim();
        if (full.isNotEmpty) {
          userName.value = full;
          return;
        }
      }

      // Fallback: use Firebase Auth displayName (Google / Facebook sign-in)
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        userName.value = user.displayName!.trim();
        return;
      }

      // Final fallback: use the part of the email before @
      final emailName = (user.email ?? '').split('@').first;
      userName.value = emailName.isNotEmpty ? emailName : 'User';
    } catch (_) {
      userName.value = 'User';
    }
  }

  // ── Req #3 ────────────────────────────────────────────────────────────────
  Future<void> _fetchFeaturedCategories() async {
    try {
      // Use single-field query to avoid needing a composite Firestore index.
      // Filter IsActive in-memory.
      final snap = await _db
          .collection('Categories')
          .where('IsFeatured', isEqualTo: true)
          .get();

      featuredCategories.value = snap.docs
          .where((d) => (d.data()['IsActive'] ?? true) == true)
          .map((d) {
            final m = d.data();
            return {
              'id': d.id,
              'name': (m['Name'] ?? '').toString(),
              'image': (m['Image'] ?? '').toString(),
              'bannerImage': (m['BannerImage'] ?? '').toString(),
            };
          })
          .toList();
    } catch (_) {}
  }

  // ── Req #4 ────────────────────────────────────────────────────────────────
  Future<void> _fetchActiveBanners() async {
    try {
      final snap = await _db
          .collection('Banners')
          .where('isActive', isEqualTo: true)
          .get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      activeBanners.value = snap.docs.where((d) {
        final m = d.data();
        // Filter by start/end date if set (format: "d/M/yyyy")
        final startDate = _parseBannerDate(
          (m['startDate'] ?? m['StartDate'] ?? '').toString(),
        );
        final endDate = _parseBannerDate(
          (m['endDate'] ?? m['EndDate'] ?? '').toString(),
        );
        if (startDate != null && today.isBefore(startDate)) return false;
        if (endDate != null && today.isAfter(endDate)) return false;
        return true;
      }).map((d) {
        final m = d.data();
        return {
          'id': d.id,
          // Accept any casing for the image field
          'image':
              (m['image'] ?? m['Image'] ?? m['imageUrl'] ?? m['ImageUrl'] ?? '')
                  .toString(),
          'title': (m['title'] ?? m['Title'] ?? '').toString(),
          'description': (m['description'] ?? m['Description'] ?? '')
              .toString(),
          'redirect': (m['redirect'] ?? m['Redirect'] ?? '').toString(),
        };
      }).toList();
    } catch (e) {
      debugPrint('⚠️ _fetchActiveBanners error: $e');
    }
  }

  /// Returns null if the string is empty or unparsable.
  DateTime? _parseBannerDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    final parts = dateStr.split('/');
    if (parts.length != 3) return null;
    try {
      final d = int.parse(parts[0]);
      final mo = int.parse(parts[1]);
      final y = int.parse(parts[2]);
      return DateTime(y, mo, d);
    } catch (_) {
      return null;
    }
  }

  // ── Req #5 ────────────────────────────────────────────────────────────────
  Future<void> _fetchRecommendedProducts() async {
    try {
      // Single-field query to avoid composite index requirement;
      // filter IsActive in-memory.
      final snap = await _db
          .collection('Products')
          .where('IsRecommended', isEqualTo: true)
          .get();

      recommendedProducts.value = snap.docs
          .where((d) => (d.data()['IsActive'] ?? true) == true)
          .map((d) => _productDocToMap(d))
          .toList();
    } catch (e) {
      // Log it so the user can actually see what went wrong
      debugPrint('⚠️ _fetchRecommendedProducts error: $e');
    }
  }

  /// Converts a Firestore product document into the canonical map used
  /// by product cards AND the product detail page.
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
      // 'image' → first image, used by product cards as thumbnail
      'image': imgs.isNotEmpty ? imgs.first : '',
      // 'images' → full list, used by the detail page image slider
      'images': imgs,
      'stock': _toInt(m['Stock']),
      'avgRating': _toDouble(m['avgRating']),
      'reviewCount': _toInt(m['reviewCount']),
    };
  }

  /// Safely convert any Firestore value to double (handles int, double, String, null)
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  /// Safely convert any Firestore value to int (handles int, double, String, null)
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // ── Req #2 ────────────────────────────────────────────────────────────────
  Future<void> searchProducts(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      searchResults.clear();
      return;
    }
    isSearching.value = true;
    try {
      final snap = await _db
          .collection('Products')
          .where('IsActive', isEqualTo: true)
          .get();

      final key = q.toLowerCase();
      searchResults.value = snap.docs.map((d) => _productDocToMap(d)).where((
        p,
      ) {
        final blob =
            '${p['name']} ${p['brandName']} ${p['categoryName']} ${p['subcategoryName']}'
                .toLowerCase();
        return blob.contains(key);
      }).toList();
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }
}
