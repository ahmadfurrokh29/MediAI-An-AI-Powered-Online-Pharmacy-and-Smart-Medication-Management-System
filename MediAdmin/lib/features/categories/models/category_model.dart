import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String image;          // category icon URL
  final String bannerImage;    // category banner URL
  final String imagePublicId;  // Cloudinary public_id for icon
  final String bannerImagePublicId; // Cloudinary public_id for banner
  final bool isFeatured;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.bannerImage,
    required this.imagePublicId,
    required this.bannerImagePublicId,
    required this.isFeatured,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  static CategoryModel empty() => CategoryModel(
    id: '',
    name: '',
    image: '',
    bannerImage: '',
    imagePublicId: '',
    bannerImagePublicId: '',
    isFeatured: false,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Image': image,
      'BannerImage': bannerImage,
      'ImagePublicId': imagePublicId,
      'BannerImagePublicId': bannerImagePublicId,
      'IsFeatured': isFeatured,
      'IsActive': isActive,
      'CreatedAt': Timestamp.fromDate(createdAt),
      'UpdatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CategoryModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (document.data() != null) {
      final data = document.data()!;
      return CategoryModel(
        id: document.id,
        name: data['Name'] ?? '',
        image: data['Image'] ?? '',
        bannerImage: data['BannerImage'] ?? '',
        imagePublicId: data['ImagePublicId'] ?? '',
        bannerImagePublicId: data['BannerImagePublicId'] ?? '',
        isFeatured: data['IsFeatured'] ?? false,
        isActive: data['IsActive'] ?? true,
        createdAt:
            (data['CreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['UpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } else {
      return CategoryModel.empty();
    }
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    String? bannerImage,
    String? imagePublicId,
    String? bannerImagePublicId,
    bool? isFeatured,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      bannerImage: bannerImage ?? this.bannerImage,
      imagePublicId: imagePublicId ?? this.imagePublicId,
      bannerImagePublicId: bannerImagePublicId ?? this.bannerImagePublicId,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
