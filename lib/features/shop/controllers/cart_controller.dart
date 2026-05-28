import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Cart item model used locally.
class CartItemModel {
  final String productId;
  final String name;
  final String brandName;
  final String image;
  final double price;
  final double salePrice;
  final int stock;
  final bool isPrescribed;
  final int tabletsInPack;
  final RxInt quantity;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.brandName,
    required this.image,
    required this.price,
    required this.salePrice,
    required this.stock,
    this.isPrescribed = false,
    this.tabletsInPack = 0,
    int quantity = 1,
  }) : quantity = quantity.obs;

  /// The effective unit price (sale price if available, else regular).
  double get unitPrice => (salePrice > 0 && salePrice < price) ? salePrice : price;

  /// Line total for this item.
  double get lineTotal => unitPrice * quantity.value;

  /// Create from Firestore Cart subcollection document.
  factory CartItemModel.fromMap(String docId, Map<String, dynamic> m) {
    return CartItemModel(
      productId: docId,
      name: (m['name'] ?? '').toString(),
      brandName: (m['brandName'] ?? '').toString(),
      image: (m['image'] ?? '').toString(),
      price: (m['price'] ?? 0).toDouble(),
      salePrice: (m['salePrice'] ?? 0).toDouble(),
      stock: (m['stock'] ?? 0) is int ? m['stock'] as int : (m['stock'] ?? 0).toInt(),
      isPrescribed: m['isPrescribed'] ?? false,
      tabletsInPack: (m['tabletsInPack'] as num? ?? 0).toInt(),
      quantity: (m['quantity'] ?? 1) is int ? m['quantity'] as int : (m['quantity'] ?? 1).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'brandName': brandName,
    'image': image,
    'price': price,
    'salePrice': salePrice,
    'stock': stock,
    'isPrescribed': isPrescribed,
    'tabletsInPack': tabletsInPack,
    'quantity': quantity.value,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class CartController extends GetxController {
  static CartController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final RxBool isLoading = false.obs;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ── Computed values ──────────────────────────────────────────────────────

  int get totalItems => cartItems.fold(0, (s, e) => s + e.quantity.value);

  double get subtotal => cartItems.fold(0.0, (s, e) => s + e.lineTotal);

  double get shippingFee => subtotal > 0 ? 120.0 : 0.0;

  double get taxFee => subtotal * 0.05; // 5 % tax

  double get totalAmount => subtotal + shippingFee + taxFee;

  /// True when at least one cart item requires a prescription.
  bool get hasPrescribedItems => cartItems.any((e) => e.isPrescribed);

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _auth.authStateChanges().first.then((_) => loadCart());
  }

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadCart() async {
    if (_uid.isEmpty) return;
    try {
      isLoading.value = true;
      final snap = await _db
          .collection('Users')
          .doc(_uid)
          .collection('Cart')
          .get();
      cartItems.value = snap.docs
          .map((d) => CartItemModel.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      // non-critical
    } finally {
      isLoading.value = false;
    }
  }

  // ── Add to cart ──────────────────────────────────────────────────────────

  /// Adds [quantity] units of the product to the cart.
  /// If already in cart, increments instead.
  /// Set [showSnackbar] to false to suppress the default snackbar.
  Future<void> addToCart(Map<String, dynamic> product, {int quantity = 1, bool showSnackbar = true}) async {
    final id = (product['id'] ?? '').toString();
    if (id.isEmpty) return;

    final existing = cartItems.firstWhereOrNull((e) => e.productId == id);
    if (existing != null) {
      existing.quantity.value += quantity;
      _persistItem(existing);
    } else {
      final item = CartItemModel(
        productId: id,
        name: (product['name'] ?? '').toString(),
        brandName: (product['brandName'] ?? '').toString(),
        image: _firstImage(product),
        price: (product['price'] as num? ?? 0).toDouble(),
        salePrice: (product['salePrice'] as num? ?? 0).toDouble(),
        stock: (product['stock'] as num? ?? 0).toInt(),
        isPrescribed: product['isPrescribed'] as bool? ?? false,
        tabletsInPack: (product['tabletsInPack'] as num? ?? 0).toInt(),
        quantity: quantity,
      );
      cartItems.add(item);
      _persistItem(item);
    }
    cartItems.refresh();
    if (showSnackbar) {
      Get.snackbar('Cart', 'Item added to cart', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Update quantity ──────────────────────────────────────────────────────

  void incrementQuantity(CartItemModel item) {
    item.quantity.value++;
    cartItems.refresh();
    _persistItem(item);
  }

  void decrementQuantity(CartItemModel item) {
    if (item.quantity.value > 1) {
      item.quantity.value--;
      cartItems.refresh();
      _persistItem(item);
    } else {
      removeItem(item.productId);
    }
  }

  // ── Remove ───────────────────────────────────────────────────────────────

  void removeItem(String productId) {
    cartItems.removeWhere((e) => e.productId == productId);
    cartItems.refresh();
    _persistRemove(productId);
  }

  // ── Clear cart ───────────────────────────────────────────────────────────

  Future<void> clearCart() async {
    cartItems.clear();
    if (_uid.isEmpty) return;
    try {
      final snap = await _db
          .collection('Users')
          .doc(_uid)
          .collection('Cart')
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
  }

  // ── Buy Now (direct checkout) ─────────────────────────────────────────

  /// Replaces the cart with a single product and returns `true` when ready.
  /// Used when the user taps "Checkout" directly from the product page.
  Future<bool> buyNow(Map<String, dynamic> product, {int quantity = 1}) async {
    final id = (product['id'] ?? '').toString();
    if (id.isEmpty) return false;

    // Clear existing cart
    await clearCart();

    // Add the single product
    final item = CartItemModel(
      productId: id,
      name: (product['name'] ?? '').toString(),
      brandName: (product['brandName'] ?? '').toString(),
      image: _firstImage(product),
      price: (product['price'] as num? ?? 0).toDouble(),
      salePrice: (product['salePrice'] as num? ?? 0).toDouble(),
      stock: (product['stock'] as num? ?? 0).toInt(),
      isPrescribed: product['isPrescribed'] as bool? ?? false,
      tabletsInPack: (product['tabletsInPack'] as num? ?? 0).toInt(),
      quantity: quantity,
    );
    cartItems.add(item);
    await _persistItem(item);
    cartItems.refresh();
    return true;
  }

  // ── Firestore persistence ────────────────────────────────────────────────

  Future<void> _persistItem(CartItemModel item) async {
    if (_uid.isEmpty) return;
    try {
      await _db
          .collection('Users')
          .doc(_uid)
          .collection('Cart')
          .doc(item.productId)
          .set(item.toMap());
    } catch (_) {}
  }

  Future<void> _persistRemove(String productId) async {
    if (_uid.isEmpty) return;
    try {
      await _db
          .collection('Users')
          .doc(_uid)
          .collection('Cart')
          .doc(productId)
          .delete();
    } catch (_) {}
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _firstImage(Map<String, dynamic> p) {
    final raw = p['images'] ?? p['image'];
    if (raw is List && raw.isNotEmpty) return raw.first.toString();
    if (raw is String && raw.isNotEmpty) return raw;
    return '';
  }
}
