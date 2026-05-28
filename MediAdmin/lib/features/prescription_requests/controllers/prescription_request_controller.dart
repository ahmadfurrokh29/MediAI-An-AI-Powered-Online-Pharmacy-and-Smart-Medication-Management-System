import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/prescription_request_model.dart';

class PrescriptionRequestController extends GetxController {
  static PrescriptionRequestController get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  final RxList<PrescriptionRequestModel> _requests =
      <PrescriptionRequestModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  List<PrescriptionRequestModel> get requests => _requests.toList();

  List<PrescriptionRequestModel> get filteredRequests {
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isEmpty) return _requests.toList();
    return _requests
        .where(
          (r) =>
              r.customerName.toLowerCase().contains(q) ||
              r.medicineName.toLowerCase().contains(q) ||
              r.customerEmail.toLowerCase().contains(q),
        )
        .toList();
  }

  int get pendingCount =>
      _requests.where((r) => r.isPending).length;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      isLoading.value = true;
      final snapshot = await _db
          .collection('PrescriptionRequests')
          .orderBy('createdAt', descending: true)
          .get();
      _requests.value = snapshot.docs
          .map((d) => PrescriptionRequestModel.fromSnapshot(d))
          .toList();
    } catch (_) {
      // Fallback without ordering
      try {
        final snapshot =
            await _db.collection('PrescriptionRequests').get();
        final list = snapshot.docs
            .map((d) => PrescriptionRequestModel.fromSnapshot(d))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _requests.value = list;
      } catch (e) {
        Get.snackbar('Error', 'Failed to load requests: $e',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Sends a notification to the customer and marks the request as Responded.
  Future<void> respondToRequest(
      PrescriptionRequestModel req, String message) async {
    try {
      final batch = _db.batch();

      // 1. Update request status
      batch.update(_db.collection('PrescriptionRequests').doc(req.id), {
        'status': 'Responded',
        'adminResponse': message,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // 2. Write notification to user's Notifications subcollection
      final notifRef = _db
          .collection('Users')
          .doc(req.customerId)
          .collection('Notifications')
          .doc();
      batch.set(notifRef, {
        'title': 'Prescription Request Update',
        'body': message,
        'requestId': req.id,
        'type': 'prescription_request',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Update local list
      final idx = _requests.indexWhere((r) => r.id == req.id);
      if (idx != -1) {
        _requests[idx] = PrescriptionRequestModel(
          id: req.id,
          customerId: req.customerId,
          customerName: req.customerName,
          customerEmail: req.customerEmail,
          medicineName: req.medicineName,
          prescriptionUrl: req.prescriptionUrl,
          status: 'Responded',
          adminResponse: message,
          createdAt: req.createdAt,
        );
        _requests.refresh();
      }

      Get.snackbar('Sent', 'Notification sent to ${req.customerName}.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to respond: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
