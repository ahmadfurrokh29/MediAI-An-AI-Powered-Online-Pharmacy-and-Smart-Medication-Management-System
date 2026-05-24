import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the Firestore `Coupons` collection document.
class CouponModel {
  final String id;
  final String code;
  final double discountValue;
  final String type; // 'PERCENTAGE' | 'FLAT'
  final String description;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int usageLimit;
  final int usageCount;
  final int perUserLimit;
  final double minOrderAmount;
  final bool stackable;
  final String targetType;
  final String campaignId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CouponModel({
    required this.id,
    required this.code,
    required this.discountValue,
    required this.type,
    this.description = '',
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.usageLimit = 100,
    this.usageCount = 0,
    this.perUserLimit = 1,
    this.minOrderAmount = 0.0,
    this.stackable = false,
    this.targetType = 'ALL',
    this.campaignId = '',
    this.createdAt,
    this.updatedAt,
  });

  factory CouponModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CouponModel(
      id: doc.id,
      code: data['Code'] ?? '',
      discountValue: (data['DiscountValue'] ?? 0).toDouble(),
      type: data['Type'] ?? 'FLAT',
      description: data['Description'] ?? '',
      isActive: data['IsActive'] ?? true,
      startDate: (data['StartDate'] as Timestamp?)?.toDate(),
      endDate: (data['EndDate'] as Timestamp?)?.toDate(),
      usageLimit: data['UsageLimit'] ?? 100,
      usageCount: data['UsageCount'] ?? 0,
      perUserLimit: data['PerUserLimit'] ?? 1,
      minOrderAmount: (data['MinOrderAmount'] ?? 0.0).toDouble(),
      stackable: data['Stackable'] ?? false,
      targetType: data['TargetType'] ?? 'ALL',
      campaignId: data['CampaignId'] ?? '',
      createdAt: (data['CreatedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['UpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory CouponModel.fromMap(String id, Map<String, dynamic> data) {
    return CouponModel(
      id: id,
      code: data['Code'] ?? '',
      discountValue: (data['DiscountValue'] ?? 0).toDouble(),
      type: data['Type'] ?? 'FLAT',
      description: data['Description'] ?? '',
      isActive: data['IsActive'] ?? true,
      startDate: (data['StartDate'] as Timestamp?)?.toDate(),
      endDate: (data['EndDate'] as Timestamp?)?.toDate(),
      usageLimit: data['UsageLimit'] ?? 100,
      usageCount: data['UsageCount'] ?? 0,
      perUserLimit: data['PerUserLimit'] ?? 1,
      minOrderAmount: (data['MinOrderAmount'] ?? 0.0).toDouble(),
      stackable: data['Stackable'] ?? false,
      targetType: data['TargetType'] ?? 'ALL',
      campaignId: data['CampaignId'] ?? '',
      createdAt: (data['CreatedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['UpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  CouponModel copyWith({int? usageCount}) {
    return CouponModel(
      id: id,
      code: code,
      discountValue: discountValue,
      type: type,
      description: description,
      isActive: isActive,
      startDate: startDate,
      endDate: endDate,
      usageLimit: usageLimit,
      usageCount: usageCount ?? this.usageCount,
      perUserLimit: perUserLimit,
      minOrderAmount: minOrderAmount,
      stackable: stackable,
      targetType: targetType,
      campaignId: campaignId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
