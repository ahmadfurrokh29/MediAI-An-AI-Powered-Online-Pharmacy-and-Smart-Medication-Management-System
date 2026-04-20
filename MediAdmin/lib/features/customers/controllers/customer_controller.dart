import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/customer_model.dart';
import '../../orders/models/order_model.dart';

class CustomerController extends GetxController {
  static CustomerController get instance => Get.find();

  final _firestore = FirebaseFirestore.instance;

  final RxList<CustomerModel> _customers = <CustomerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasInitialized = false.obs;
  final RxString searchQuery = ''.obs;

  List<CustomerModel> get customers => _customers.toList();

  List<CustomerModel> get filteredCustomers {
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isEmpty) return _customers.toList();
    return _customers
        .where(
          (c) =>
              c.fullName.toLowerCase().contains(q) ||
              c.email.toLowerCase().contains(q) ||
              c.phoneNumber.contains(q),
        )
        .toList();
  }

  Future<void> initialize() async {
    if (hasInitialized.value) return;
    await fetchCustomers();
    hasInitialized.value = true;
  }

  Future<void> fetchCustomers() async {
    try {
      isLoading.value = true;

      // Fetch ONLY documents with role == 'Customer' (exact match, case-sensitive)
      // Customers come from the e-commerce app Users collection with role='Customer'
      // Admins are stored in the separate Admins collection and should never appear here
      final snapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'Customer')
          .get();

      List<CustomerModel> list = snapshot.docs
          .map((doc) => CustomerModel.fromSnapshot(doc))
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _customers.value = list;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch customers: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<OrderModel>> fetchOrdersForCustomer(String customerId) async {
    try {
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('Orders')
            .where('customerId', isEqualTo: customerId)
            .orderBy('createdAt', descending: true)
            .get();
      } catch (_) {
        snapshot = await _firestore
            .collection('Orders')
            .where('customerId', isEqualTo: customerId)
            .get();
      }

      // Also try userId field
      if (snapshot.docs.isEmpty) {
        try {
          snapshot = await _firestore
              .collection('Orders')
              .where('userId', isEqualTo: customerId)
              .get();
        } catch (_) {}
      }

      final list = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _firestore.collection('Users').doc(customerId).delete();
      _customers.removeWhere((c) => c.id == customerId);
      Get.snackbar(
        'Success',
        'Customer deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete customer: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String formatDate(DateTime dt) =>
      DateFormat('dd/MM/yyyy \'at\' H:mm').format(dt);
}
