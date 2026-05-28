import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:med/common/widgets/success_screen/success_screen.dart';
import 'package:med/features/personalization/controllers/address_controller.dart';
import 'package:med/features/personalization/controllers/user_controller.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/features/shop/controllers/coupon_controller.dart';
import 'package:med/features/shop/controllers/payment_controller.dart';
import 'package:med/features/shop/models/order_model.dart';
import 'package:med/navigation_menu.dart';
import 'package:med/utils/constants/image_strings.dart';

class OrderController extends GetxController {
  static OrderController get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  /// Base64-encoded prescription images attached to the current checkout.
  /// Cleared after the order is placed successfully.
  final RxList<String> prescriptions = <String>[].obs;

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  StreamSubscription<QuerySnapshot>? _deliveredSub;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
    _startDeliveredOrdersListener();
  }

  @override
  void onClose() {
    _deliveredSub?.cancel();
    super.onClose();
  }

  // ── Prescription helpers ──────────────────────────────────────────────────

  /// Opens the gallery and adds the selected image (compressed) to [prescriptions].
  Future<void> pickPrescription() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 1200,
        imageQuality: 50,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      prescriptions.add(base64Encode(bytes));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void removePrescription(int index) {
    if (index >= 0 && index < prescriptions.length) {
      prescriptions.removeAt(index);
    }
  }

  /// Auto-attaches prescription images stored in LocalDB for prescribed cart
  /// items. Matches by medicine name (case-insensitive contains check).
  /// Safe to call multiple times — skips if prescriptions are already loaded,
  /// and de-duplicates images from LocalDB.
  Future<void> autoAttachPrescriptionsFromLocalDB() async {
    // Only auto-attach when the list is currently empty (don't overwrite
    // prescriptions the user has already manually uploaded / removed).
    if (prescriptions.isNotEmpty) return;

    try {
      final cart = CartController.instance;
      final prescribedNames = cart.cartItems
          .where((e) => e.isPrescribed)
          .map((e) => e.name)
          .where((n) => n.isNotEmpty)
          .toList();

      if (prescribedNames.isEmpty) return;

      final images = await LocalDB.getPrescriptionImagesForNames(
        uid,
        prescribedNames,
      );
      for (final img in images) {
        if (!prescriptions.contains(img)) {
          prescriptions.add(img);
        }
      }
    } catch (_) {
      // Silent failure — user can always upload manually.
    }
  }



  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;
      error.value = '';
      if (uid.isEmpty) return;

      try {
        // Primary: uses composite index (customerId + createdAt DESC)
        final snapshot = await _db
            .collection('Orders')
            .where('customerId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .get();

        orders.value = snapshot.docs
            .map((doc) => OrderModel.fromSnapshot(doc))
            .toList();
      } catch (_) {
        // Fallback: index may not be ready yet — fetch without ordering
        final snapshot = await _db
            .collection('Orders')
            .where('customerId', isEqualTo: uid)
            .get();

        final list = snapshot.docs
            .map((doc) => OrderModel.fromSnapshot(doc))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        orders.value = list;
      }

      // Process stock refill for any delivered orders in background
      _processDeliveredOrdersStockRefill();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // ── Delivered-order stock refill ──────────────────────────────────────────

  /// Real-time listener: fires immediately whenever a "Delivered" order
  /// appears (new or status just changed). De-duplicated by [LocalDB].
  void _startDeliveredOrdersListener() {
    if (uid.isEmpty) return;
    _deliveredSub = _db
        .collection('Orders')
        .where('customerId', isEqualTo: uid)
        .where('orderStatus', isEqualTo: 'Delivered')
        .snapshots()
        .listen((snap) {
          for (final change in snap.docChanges) {
            final order = OrderModel.fromSnapshot(change.doc);
            _refillStockForDeliveredOrder(order);
          }
        });
  }

  /// Called after [fetchOrders] to catch any delivered orders that were
  /// processed while the app was closed.
  void _processDeliveredOrdersStockRefill() {
    for (final order in orders) {
      if (order.orderStatus == 'Delivered') {
        _refillStockForDeliveredOrder(order);
      }
    }
  }

  /// Refills LocalDB medicine stock for each item in [order].
  /// Safe to call multiple times — skips already-processed orders.
  Future<void> _refillStockForDeliveredOrder(OrderModel order) async {
    if (order.id.isEmpty) return;
    if (await LocalDB.isOrderStockRefilled(order.id)) return;

    try {
      final medicines = await LocalDB.getUserMedicines(uid);
      if (medicines.isEmpty) return;

      for (final item in order.items) {
        final tabletsPerUnit = item.tabletsInPack > 0 ? item.tabletsInPack : 1;
        final tabletsToAdd = item.quantity * tabletsPerUnit;
        final productName = item.productName.toLowerCase().trim();
        if (productName.isEmpty) continue;

        for (final med in medicines) {
          final medName =
              (med['medicine_name'] as String? ?? '').toLowerCase().trim();
          if (medName.isEmpty) continue;
          if (medName.contains(productName) || productName.contains(medName)) {
            final currentStock =
                (med['available_stock'] as num? ?? 0).toInt();
            final currentDoses =
                (med['total_no_of_doses'] as num? ?? 0).toInt();
            await LocalDB.updateMedicineStats(
              med['medId'] as String,
              currentDoses,
              currentStock + tabletsToAdd,
            );
            break; // only refill the first matching medicine
          }
        }
      }

      await LocalDB.markOrderStockRefilled(order.id);
    } catch (_) {
      // Silent — stock refill is best-effort; user can adjust manually
    }
  }

  // ── Place order ─────────────────────────────────────────────────────────

  Future<void> placeOrder() async {
    try {
      isLoading.value = true;

      final cart = CartController.instance;
      final payment = Get.find<PaymentController>();
      final addrCtrl = Get.find<AddressController>();
      final user = UserController.instance.user.value;

      if (cart.cartItems.isEmpty) {
        Get.snackbar(
          'Cart Empty',
          'Add items to cart before placing an order.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Prescription check
      if (cart.hasPrescribedItems && prescriptions.isEmpty) {
        Get.snackbar(
          'Prescription Required',
          'One or more items in your cart require a prescription. Please upload your prescription before placing the order.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      if (!addrCtrl.hasAddresses) {
        Get.snackbar(
          'No Address',
          'Please add a shipping address first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Build order items from cart
      final items = cart.cartItems
          .map(
            (ci) => OrderItemModel(
              productId: ci.productId,
              productName: ci.name,
              price: ci.unitPrice,
              quantity: ci.quantity.value,
              isPrescribed: ci.isPrescribed,
              tabletsInPack: ci.tabletsInPack,
            ),
          )
          .toList();

      final selectedAddr = addrCtrl.selectedAddress;

      // ── Coupon integration ─────────────────────────────────────────────
      final couponCtrl = Get.find<CouponController>();
      final appliedCoupon = couponCtrl.appliedCoupon.value;
      final couponCode = appliedCoupon?.code ?? '';
      final couponDiscount = couponCtrl.discountAmount.value;
      final finalTotal =
          cart.subtotal + cart.shippingFee + cart.taxFee - couponDiscount;

      final order = OrderModel(
        id: '', // Firestore will assign
        customerId: uid,
        customerName: user.fullName,
        customerEmail: user.email,
        orderStatus: 'Pending',
        paymentStatus: payment.paymentStatusForOrder,
        totalAmount: finalTotal.clamp(0, double.infinity),
        subtotal: cart.subtotal,
        couponCode: couponCode,
        couponDiscount: couponDiscount,
        shippingFee: cart.shippingFee,
        createdAt: DateTime.now(),
        shippingAddress: selectedAddr,
        items: items,
        prescriptions: List<String>.from(prescriptions),
      );

      // Write to Firestore
      final docRef = await _db.collection('Orders').add(order.toMap());

      // Redeem coupon server-side (FastAPI + Firestore) if applied
      if (appliedCoupon != null) {
        await couponCtrl.redeemAppliedCoupon(docRef.id);
      }

      // Clear cart
      await cart.clearCart();

      // Clear prescriptions
      prescriptions.clear();

      // Refresh orders list
      await fetchOrders();
      // Navigate to success screen
      Get.off(
        () => SuccessScreen(
          image: MImages.staticSuccessIllustration,
          title: 'Order Placed!',
          subTitle: payment.selectedMethod.value == PaymentMethod.cashOnDelivery
              ? 'Your order has been placed.\nPlease pay upon delivery.'
              : 'Payment successful. Your order will be shipped soon!',
          onPressed: () => Get.offAll(() => const NavigationMenu()),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to place order: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
