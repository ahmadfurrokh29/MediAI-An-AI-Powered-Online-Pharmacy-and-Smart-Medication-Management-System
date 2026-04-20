import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;
  final num discountValue;
  final String type; // 'PERCENTAGE' or 'FLAT'
  final String description;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int usageLimit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CouponModel({
    this.id = '',
    required this.code,
    required this.discountValue,
    required this.type,
    this.description = '',
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.usageLimit = 100,
    this.createdAt,
    this.updatedAt,
  });

  CouponModel copyWith({
    String? id,
    String? code,
    num? discountValue,
    String? type,
    String? description,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    int? usageLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CouponModel(
      id: id ?? this.id,
      code: code ?? this.code,
      discountValue: discountValue ?? this.discountValue,
      type: type ?? this.type,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      usageLimit: usageLimit ?? this.usageLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Code': code,
      'DiscountValue': discountValue,
      'Type': type,
      'Description': description,
      'IsActive': isActive,
      'StartDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'EndDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'UsageLimit': usageLimit,
      'CreatedAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'UpdatedAt': Timestamp.now(),
    };
  }

  factory CouponModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CouponModel(
      id: doc.id,
      code: data['Code'] ?? '',
      discountValue: data['DiscountValue'] ?? 0,
      type: data['Type'] ?? 'FLAT',
      description: data['Description'] ?? '',
      isActive: data['IsActive'] ?? true,
      startDate: (data['StartDate'] as Timestamp?)?.toDate(),
      endDate: (data['EndDate'] as Timestamp?)?.toDate(),
      usageLimit: data['UsageLimit'] ?? 100,
      createdAt: (data['CreatedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['UpdatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
