import 'package:cloud_firestore/cloud_firestore.dart';

class BrandModel {
  final String id;
  final String name;
  final String image;
  final List<String> categoryIds;
  final bool isFeatured;
  final bool isActive;
  final int productCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BrandModel({
    required this.id,
    required this.name,
    required this.image,
    required this.categoryIds,
    required this.isFeatured,
    required this.isActive,
    required this.productCount,
    required this.createdAt,
    required this.updatedAt,
  });

  static BrandModel empty() => BrandModel(
    id: '',
    name: '',
    image: '',
    categoryIds: [],
    isFeatured: false,
    isActive: true,
    productCount: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Image': image,
      'CategoryIds': categoryIds,
      'IsFeatured': isFeatured,
      'IsActive': isActive,
      'ProductCount': productCount,
      'CreatedAt': Timestamp.fromDate(createdAt),
      'UpdatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BrandModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (document.data() != null) {
      final data = document.data()!;
      return BrandModel(
        id: document.id,
        name: data['Name'] ?? '',
        image: data['Image'] ?? '',
        categoryIds: List<String>.from(data['CategoryIds'] ?? []),
        isFeatured: data['IsFeatured'] ?? false,
        isActive: data['IsActive'] ?? true,
        productCount: data['ProductCount'] ?? 0,
        createdAt:
            (data['CreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['UpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } else {
      return BrandModel.empty();
    }
  }

  BrandModel copyWith({
    String? id,
    String? name,
    String? image,
    List<String>? categoryIds,
    bool? isFeatured,
    bool? isActive,
    int? productCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      categoryIds: categoryIds ?? this.categoryIds,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
