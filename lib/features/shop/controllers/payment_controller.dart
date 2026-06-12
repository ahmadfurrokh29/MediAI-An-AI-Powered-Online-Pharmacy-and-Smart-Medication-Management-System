import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/payment_method_model.dart';

/// Manages saved payment methods for the current user.
///
/// Payment methods are persisted in:
///   `Users/{uid}/PaymentMethods/{docId}`
///
/// The [selectedMethod] observable (null == Cash on Delivery) drives both
/// the checkout screen and the order-placement flow in [OrderController].
class PaymentController extends GetxController {
  static PaymentController get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── State ─────────────────────────────────────────────────────────────────

  /// All saved payment methods for the current user.
  final RxList<PaymentMethodModel> paymentMethods = <PaymentMethodModel>[].obs;

  final RxBool isLoading = false.obs;

  /// Currently selected method for checkout.
  /// null  →  Cash on Delivery (no stored method needed).
  final Rx<PaymentMethodModel?> selectedMethod = Rx<PaymentMethodModel?>(null);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchPaymentMethods();
  }

  // ── Firestore CRUD ────────────────────────────────────────────────────────

  Future<void> fetchPaymentMethods() async {
    if (uid.isEmpty) return;
    isLoading.value = true;
    try {
      final snap = await _db
          .collection('Users')
          .doc(uid)
          .collection('PaymentMethods')
          .orderBy('createdAt', descending: true)
          .get();
      paymentMethods.value = snap.docs
          .map((d) => PaymentMethodModel.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      // Firestore index may not exist yet — retry without ordering.
      try {
        final snap = await _db
            .collection('Users')
            .doc(uid)
            .collection('PaymentMethods')
            .get();
        final list = snap.docs
            .map((d) => PaymentMethodModel.fromMap(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        paymentMethods.value = list;
      } catch (_) {}
    } finally {
      isLoading.value = false;
    }
  }

  /// Saves a new payment method to Firestore and inserts it at the top of
  /// the local list.
  Future<void> addPaymentMethod(PaymentMethodModel method) async {
    if (uid.isEmpty) return;
    isLoading.value = true;
    try {
      final ref = await _db
          .collection('Users')
          .doc(uid)
          .collection('PaymentMethods')
          .add(method.toMap());

      final saved = PaymentMethodModel.fromMap(ref.id, method.toMap());
      paymentMethods.insert(0, saved);

      Get.snackbar(
        'Saved',
        '${method.typeLabel} added successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save payment method: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Deletes a saved payment method from Firestore and the local list.
  Future<void> removePaymentMethod(String docId) async {
    if (uid.isEmpty) return;
    try {
      await _db
          .collection('Users')
          .doc(uid)
          .collection('PaymentMethods')
          .doc(docId)
          .delete();
      paymentMethods.removeWhere((m) => m.id == docId);
      // Deselect if it was the active method.
      if (selectedMethod.value?.id == docId) {
        selectedMethod.value = null;
      }
      Get.snackbar(
        'Removed',
        'Payment method removed.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ── Computed helpers ──────────────────────────────────────────────────────

  /// True when the user chose Cash on Delivery (no card/wallet selected).
  bool get isCOD => selectedMethod.value == null;

  /// Label shown in the checkout UI.
  String get methodLabel {
    if (selectedMethod.value == null) return 'Cash on Delivery';
    return selectedMethod.value!.typeLabel;
  }

  /// String stored on the Order document.
  String get paymentMethodString {
    if (selectedMethod.value == null) return 'Cash on Delivery';
    return selectedMethod.value!.typeLabel;
  }

  /// Payment status written to the Order document immediately on placement.
  ///
  ///  - COD orders are "Unpaid" (payment happens on delivery).
  ///  - All other methods are "Paid" (mock engine always succeeds).
  String get paymentStatusForOrder {
    return isCOD ? 'Unpaid' : 'Paid';
  }

  // ── Legacy compat (still referenced in a few places) ─────────────────────
  bool get hasCard =>
      paymentMethods.any((m) => m.type == PaymentMethodType.card);
}
