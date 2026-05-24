import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a promotional campaign that distributes one or more coupons
/// to a targeted set of users.
class CampaignModel {
  final String id;
  final String name;
  final String description;
  final String couponId;
  final String couponCode;
  final String
  status; // 'DRAFT', 'SCHEDULED', 'ACTIVE', 'COMPLETED', 'CANCELLED'
  final String targetType; // 'ALL', 'SEGMENT', 'SPECIFIC'
  final List<String> targetUserIds; // used when targetType == 'SPECIFIC'
  final String
  targetSegment; // used when targetType == 'SEGMENT' e.g. 'NEW_USERS'
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int totalTargeted;
  final int totalSent;
  final int totalAccepted;
  final int totalDeclined;
  final int totalRedeemed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CampaignModel({
    this.id = '',
    required this.name,
    this.description = '',
    required this.couponId,
    required this.couponCode,
    this.status = 'DRAFT',
    this.targetType = 'ALL',
    this.targetUserIds = const [],
    this.targetSegment = '',
    this.scheduledAt,
    this.sentAt,
    this.totalTargeted = 0,
    this.totalSent = 0,
    this.totalAccepted = 0,
    this.totalDeclined = 0,
    this.totalRedeemed = 0,
    this.createdAt,
    this.updatedAt,
  });

  CampaignModel copyWith({
    String? id,
    String? name,
    String? description,
    String? couponId,
    String? couponCode,
    String? status,
    String? targetType,
    List<String>? targetUserIds,
    String? targetSegment,
    DateTime? scheduledAt,
    DateTime? sentAt,
    int? totalTargeted,
    int? totalSent,
    int? totalAccepted,
    int? totalDeclined,
    int? totalRedeemed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      couponId: couponId ?? this.couponId,
      couponCode: couponCode ?? this.couponCode,
      status: status ?? this.status,
      targetType: targetType ?? this.targetType,
      targetUserIds: targetUserIds ?? this.targetUserIds,
      targetSegment: targetSegment ?? this.targetSegment,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      totalTargeted: totalTargeted ?? this.totalTargeted,
      totalSent: totalSent ?? this.totalSent,
      totalAccepted: totalAccepted ?? this.totalAccepted,
      totalDeclined: totalDeclined ?? this.totalDeclined,
      totalRedeemed: totalRedeemed ?? this.totalRedeemed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Description': description,
      'CouponId': couponId,
      'CouponCode': couponCode,
      'Status': status,
      'TargetType': targetType,
      'TargetUserIds': targetUserIds,
      'TargetSegment': targetSegment,
      'ScheduledAt': scheduledAt != null
          ? Timestamp.fromDate(scheduledAt!)
          : null,
      'SentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'TotalTargeted': totalTargeted,
      'TotalSent': totalSent,
      'TotalAccepted': totalAccepted,
      'TotalDeclined': totalDeclined,
      'TotalRedeemed': totalRedeemed,
      'CreatedAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'UpdatedAt': Timestamp.now(),
    };
  }

  factory CampaignModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CampaignModel(
      id: doc.id,
      name: data['Name'] ?? '',
      description: data['Description'] ?? '',
      couponId: data['CouponId'] ?? '',
      couponCode: data['CouponCode'] ?? '',
      status: data['Status'] ?? 'DRAFT',
      targetType: data['TargetType'] ?? 'ALL',
      targetUserIds: List<String>.from(data['TargetUserIds'] ?? []),
      targetSegment: data['TargetSegment'] ?? '',
      scheduledAt: (data['ScheduledAt'] as Timestamp?)?.toDate(),
      sentAt: (data['SentAt'] as Timestamp?)?.toDate(),
      totalTargeted: data['TotalTargeted'] ?? 0,
      totalSent: data['TotalSent'] ?? 0,
      totalAccepted: data['TotalAccepted'] ?? 0,
      totalDeclined: data['TotalDeclined'] ?? 0,
      totalRedeemed: data['TotalRedeemed'] ?? 0,
      createdAt: (data['CreatedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['UpdatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
