import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/success_screen/success_screen.dart';
import 'package:med/features/personalization/controllers/address_controller.dart';
import 'package:med/features/personalization/controllers/user_controller.dart';
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

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
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
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
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
      );

      // Write to Firestore
      final docRef = await _db.collection('Orders').add(order.toMap());

      // Redeem coupon server-side (FastAPI + Firestore) if applied
      if (appliedCoupon != null) {
        await couponCtrl.redeemAppliedCoupon(docRef.id);
      }

      // Clear cart
      await cart.clearCart();

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
