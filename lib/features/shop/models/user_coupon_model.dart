import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks a coupon's lifecycle for a specific user.
/// Lives in the Firestore `UserCoupons` collection.
class UserCouponModel {
  final String id; // Firestore document ID
  final String userId;
  final String couponId;
  final String campaignId;
  final String status; // PENDING | ACCEPTED | DECLINED | REDEEMED | EXPIRED
  final DateTime? receivedAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? redeemedAt;

  // Denormalized coupon fields for fast local display
  final String couponCode;
  final double discountValue;
  final String discountType;
  final String description;
  final DateTime? expiresAt;

  const UserCouponModel({
    required this.id,
    required this.userId,
    required this.couponId,
    this.campaignId = '',
    required this.status,
    this.receivedAt,
    this.acceptedAt,
    this.declinedAt,
    this.redeemedAt,
    this.couponCode = '',
    this.discountValue = 0.0,
    this.discountType = 'FLAT',
    this.description = '',
    this.expiresAt,
  });

  bool get isAccepted => status == 'ACCEPTED';
  bool get isPending => status == 'PENDING';
  bool get isRedeemed => status == 'REDEEMED';
  bool get isDeclined => status == 'DECLINED';
  bool get isExpired =>
      status == 'EXPIRED' ||
      (expiresAt != null && DateTime.now().isAfter(expiresAt!));

  factory UserCouponModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserCouponModel(
      id: doc.id,
      userId: data['UserId'] ?? '',
      couponId: data['CouponId'] ?? '',
      campaignId: data['CampaignId'] ?? '',
      status: data['Status'] ?? 'PENDING',
      receivedAt: (data['ReceivedAt'] as Timestamp?)?.toDate(),
      acceptedAt: (data['AcceptedAt'] as Timestamp?)?.toDate(),
      declinedAt: (data['DeclinedAt'] as Timestamp?)?.toDate(),
      redeemedAt: (data['RedeemedAt'] as Timestamp?)?.toDate(),
      couponCode: data['CouponCode'] ?? '',
      discountValue: (data['DiscountValue'] ?? 0.0).toDouble(),
      discountType: data['DiscountType'] ?? 'FLAT',
      description: data['Description'] ?? '',
      expiresAt: (data['ExpiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'UserId': userId,
      'CouponId': couponId,
      'CampaignId': campaignId,
      'Status': status,
      'ReceivedAt': receivedAt != null ? Timestamp.fromDate(receivedAt!) : null,
      'AcceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'DeclinedAt': declinedAt != null ? Timestamp.fromDate(declinedAt!) : null,
      'RedeemedAt': redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
      'CouponCode': couponCode,
      'DiscountValue': discountValue,
      'DiscountType': discountType,
      'Description': description,
      'ExpiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  UserCouponModel copyWith({
    String? status,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? redeemedAt,
  }) {
    return UserCouponModel(
      id: id,
      userId: userId,
      couponId: couponId,
      campaignId: campaignId,
      status: status ?? this.status,
      receivedAt: receivedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      couponCode: couponCode,
      discountValue: discountValue,
      discountType: discountType,
      description: description,
      expiresAt: expiresAt,
    );
  }
}
