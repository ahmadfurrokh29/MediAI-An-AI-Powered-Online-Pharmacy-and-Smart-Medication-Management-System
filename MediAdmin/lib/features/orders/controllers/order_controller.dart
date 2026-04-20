import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';

class OrderController extends GetxController {
  static OrderController get instance => Get.find();

  final _firestore = FirebaseFirestore.instance;

  final RxList<OrderModel> _orders = <OrderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasInitialized = false.obs;
  final RxString searchQuery = ''.obs;

  // Status being updated
  final RxString updatingOrderId = ''.obs;

  List<OrderModel> get orders => _orders.toList();

  List<OrderModel> get filteredOrders {
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isEmpty) return _orders.toList();
    return _orders
        .where(
          (o) =>
              o.id.toLowerCase().contains(q) ||
              o.customerName.toLowerCase().contains(q) ||
              o.customerEmail.toLowerCase().contains(q) ||
              o.orderStatus.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> initialize() async {
    if (hasInitialized.value) return;
    await fetchOrders();
    hasInitialized.value = true;
  }

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore
          .collection('Orders')
          .orderBy('createdAt', descending: true)
          .get();
      _orders.value = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      // Fallback: try without ordering (if index not ready)
      try {
        final snapshot = await _firestore.collection('Orders').get();
        final list = snapshot.docs
            .map((doc) => OrderModel.fromSnapshot(doc))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _orders.value = list;
      } catch (e2) {
        Get.snackbar(
          'Error',
          'Failed to fetch orders: $e2',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      updatingOrderId.value = orderId;

      final updates = <String, dynamic>{'orderStatus': newStatus};

      // When marking a COD order as Delivered, auto-set paymentStatus to Paid
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1 &&
          newStatus == 'Delivered' &&
          _orders[idx].paymentStatus == 'Unpaid') {
        updates['paymentStatus'] = 'Paid';
      }

      await _firestore.collection('Orders').doc(orderId).update(updates);

      if (idx != -1) {
        _orders[idx] = _orders[idx].copyWith(
          orderStatus: newStatus,
          paymentStatus: updates['paymentStatus'] as String?,
        );
        _orders.refresh();
      }
      Get.snackbar(
        'Success',
        'Order status updated to $newStatus',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      updatingOrderId.value = '';
    }
  }

  Future<void> updatePaymentStatus(String orderId, String newStatus) async {
    try {
      updatingOrderId.value = orderId;
      await _firestore.collection('Orders').doc(orderId).update({
        'paymentStatus': newStatus,
      });
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = _orders[idx].copyWith(paymentStatus: newStatus);
        _orders.refresh();
      }
      Get.snackbar(
        'Success',
        'Payment status updated to $newStatus',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update payment status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      updatingOrderId.value = '';
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('Orders').doc(orderId).delete();
      _orders.removeWhere((o) => o.id == orderId);
      Get.snackbar(
        'Success',
        'Order deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete order: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ── Today's stats ──
  List<OrderModel> get todayOrders {
    final now = DateTime.now();
    return _orders
        .where(
          (o) =>
              o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day,
        )
        .toList();
  }

  double get todaySalesTotal =>
      todayOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

  double get todayAvgOrderValue {
    final t = todayOrders;
    if (t.isEmpty) return 0.0;
    return todaySalesTotal / t.length;
  }

  int get todayTotalOrders => todayOrders.length;

  int get todaySoldProducts => todayOrders.fold(
    0,
    (sum, o) => sum + o.items.fold(0, (s, i) => s + i.quantity),
  );

  // ── Status counts (all time for chart) ──
  int statusCount(String status) => _orders
      .where((o) => o.orderStatus.toLowerCase() == status.toLowerCase())
      .length;

  // ── Recent orders (last 5) ──
  List<OrderModel> get recentOrders => _orders.take(5).toList();

  String formatDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);
}
