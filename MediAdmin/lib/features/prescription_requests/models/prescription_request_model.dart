import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionRequestModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String medicineName;
  final String prescriptionUrl;
  final String status; // 'Pending' | 'Responded'
  final String adminResponse;
  final DateTime createdAt;

  const PrescriptionRequestModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.medicineName,
    required this.prescriptionUrl,
    required this.status,
    required this.adminResponse,
    required this.createdAt,
  });

  bool get isPending => status == 'Pending';

  factory PrescriptionRequestModel.fromSnapshot(DocumentSnapshot snap) {
    final d = snap.data() as Map<String, dynamic>;
    DateTime createdAt = DateTime.now();
    final ts = d['createdAt'];
    if (ts is Timestamp) createdAt = ts.toDate();

    return PrescriptionRequestModel(
      id: snap.id,
      customerId: d['customerId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? '',
      customerEmail: d['customerEmail'] as String? ?? '',
      medicineName: d['medicineName'] as String? ?? '',
      // Support both new (prescriptionUrl) and legacy (prescriptionBase64) docs
      prescriptionUrl: d['prescriptionUrl'] as String? ??
          d['prescriptionBase64'] as String? ?? '',
      status: d['status'] as String? ?? 'Pending',
      adminResponse: d['adminResponse'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}
