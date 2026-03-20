import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Manages the current user's wishlist.
///
/// Wishlisted product IDs are stored in:
///   Firestore → Users/{uid}/Wishlist  (subcollection, doc-id = productId)
///
/// The full product maps are kept in [wishlistProducts] so the wishlist
/// screen can render cards without an extra fetch.
class WishlistController extends GetxController {
  static WishlistController get instance => Get.find<WishlistController>();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Set of product IDs currently in the wishlist.
  final RxSet<String> wishlistIds = <String>{}.obs;

  /// Full product data maps for wishlisted products.
  final RxList<Map<String, dynamic>> wishlistProducts =
      <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load wishlist once the Firebase Auth session is restored.
    _auth.authStateChanges().first.then((_) => _loadWishlist());
  }

  // ── Public helpers ──────────────────────────────────────────────────────

  bool isWishlisted(String productId) => wishlistIds.contains(productId);

  /// Toggle the wishlist state for [productId].
  /// [productData] is the full product map from HomeController —
  /// used to persist the product details locally so the wishlist screen
  /// can display cards without re-fetching.
  Future<void> toggleWishlist(
    String productId,
    Map<String, dynamic>? productData,
  ) async {
    if (productId.isEmpty) return;

    if (wishlistIds.contains(productId)) {
      // ── Remove ──
      wishlistIds.remove(productId);
      wishlistProducts.removeWhere((p) => p['id'] == productId);
      _persistRemove(productId);
    } else {
      // ── Add ──
      wishlistIds.add(productId);
      if (productData != null) {
        wishlistProducts.add(productData);
      }
      _persistAdd(productId, productData);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<void> _loadWishlist() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      isLoading.value = true;
      final snap = await _db
          .collection('Users')
          .doc(uid)
          .collection('Wishlist')
          .get();

      wishlistIds
        ..clear()
        ..addAll(snap.docs.map((d) => d.id).toSet());
      wishlistProducts.value = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': (data['name'] ?? '').toString(),
          'brandName': (data['brandName'] ?? '').toString(),
          'price': (data['price'] ?? 0).toDouble(),
          'salePrice': (data['salePrice'] ?? 0).toDouble(),
          'image': (data['image'] ?? '').toString(),
          'stock': (data['stock'] ?? 0),
        };
      }).toList();
    } catch (_) {
      // Silently fail — wishlist is non-critical
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _persistAdd(
    String productId,
    Map<String, dynamic>? productData,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db
          .collection('Users')
          .doc(uid)
          .collection('Wishlist')
          .doc(productId)
          .set({
            'name': productData?['name'] ?? '',
            'brandName': productData?['brandName'] ?? '',
            'price': productData?['price'] ?? 0,
            'salePrice': productData?['salePrice'] ?? 0,
            'image': productData?['image'] ?? '',
            'stock': productData?['stock'] ?? 0,
            'addedAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  Future<void> _persistRemove(String productId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db
          .collection('Users')
          .doc(uid)
          .collection('Wishlist')
          .doc(productId)
          .delete();
    } catch (_) {}
  }
}
