import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String imagePublicId; // Cloudinary public_id for deletion
  final String title;
  final String description;
  final String redirect;
  final bool isActive;
  final bool isFeatured;
  final int views;
  final int clicks;
  final String startDate;
  final String endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.imagePublicId,
    required this.title,
    required this.description,
    required this.redirect,
    required this.isActive,
    required this.isFeatured,
    required this.views,
    required this.clicks,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  static BannerModel empty() => BannerModel(
    id: '',
    imageUrl: '',
    imagePublicId: '',
    title: '',
    description: '',
    redirect: '',
    isActive: true,
    isFeatured: false,
    views: 0,
    clicks: 0,
    startDate: '',
    endDate: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// Converts to Firestore document map.
  /// Field names match what the customer app reads:
  ///   image / title / description / redirect / isActive / isFeatured
  Map<String, dynamic> toJson() {
    return {
      'image': imageUrl,
      'imagePublicId': imagePublicId,
      'title': title,
      'description': description,
      'redirect': redirect,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'views': views,
      'clicks': clicks,
      'startDate': startDate,
      'endDate': endDate,
      'CreatedAt': Timestamp.fromDate(createdAt),
      'UpdatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BannerModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return BannerModel.empty();
    return BannerModel(
      id: doc.id,
      imageUrl: (data['image'] ?? data['imageUrl'] ?? data['ImageUrl'] ?? '')
          .toString(),
      imagePublicId: (data['imagePublicId'] ?? '').toString(),
      title: (data['title'] ?? data['Title'] ?? '').toString(),
      description: (data['description'] ?? data['Description'] ?? '')
          .toString(),
      redirect: (data['redirect'] ?? data['Redirect'] ?? '').toString(),
      isActive: data['isActive'] ?? data['IsActive'] ?? true,
      isFeatured: data['isFeatured'] ?? data['IsFeatured'] ?? false,
      views: (data['views'] ?? data['Views'] ?? 0) as int,
      clicks: (data['clicks'] ?? data['Clicks'] ?? 0) as int,
      startDate: (data['startDate'] ?? data['StartDate'] ?? '').toString(),
      endDate: (data['endDate'] ?? data['EndDate'] ?? '').toString(),
      createdAt: (data['CreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['UpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  BannerModel copyWith({
    String? id,
    String? imageUrl,
    String? imagePublicId,
    String? title,
    String? description,
    String? redirect,
    bool? isActive,
    bool? isFeatured,
    int? views,
    int? clicks,
    String? startDate,
    String? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePublicId: imagePublicId ?? this.imagePublicId,
      title: title ?? this.title,
      description: description ?? this.description,
      redirect: redirect ?? this.redirect,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      views: views ?? this.views,
      clicks: clicks ?? this.clicks,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
