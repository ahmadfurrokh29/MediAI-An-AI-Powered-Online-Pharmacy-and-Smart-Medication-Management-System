import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userImage;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? adminReply;
  final DateTime? adminReplyDate;

  const ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.adminReply,
    this.adminReplyDate,
  });

  static ReviewModel fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ReviewModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userImage: data['userImage'],
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminReply: data['adminReply'],
      adminReplyDate: (data['adminReplyDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'userId': userId,
    'userName': userName,
    'userImage': userImage,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
    'adminReply': adminReply,
    'adminReplyDate': adminReplyDate != null
        ? Timestamp.fromDate(adminReplyDate!)
        : null,
  };
}
