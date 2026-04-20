import 'package:cloud_firestore/cloud_firestore.dart';

class SubcategoryModel {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String image;
  final bool isFeatured;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubcategoryModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.image,
    required this.isFeatured,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  static SubcategoryModel empty() => SubcategoryModel(
    id: '',
    name: '',
    categoryId: '',
    categoryName: '',
    image: '',
    isFeatured: false,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'CategoryId': categoryId,
      'CategoryName': categoryName,
      'Image': image,
      'IsFeatured': isFeatured,
      'IsActive': isActive,
      'CreatedAt': Timestamp.fromDate(createdAt),
      'UpdatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SubcategoryModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (document.data() != null) {
      final data = document.data()!;
      return SubcategoryModel(
        id: document.id,
        name: data['Name'] ?? '',
        categoryId: data['CategoryId'] ?? '',
        categoryName: data['CategoryName'] ?? '',
        image: data['Image'] ?? '',
        isFeatured: data['IsFeatured'] ?? false,
        isActive: data['IsActive'] ?? true,
        createdAt:
            (data['CreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['UpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } else {
      return SubcategoryModel.empty();
    }
  }

  SubcategoryModel copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    String? image,
    bool? isFeatured,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubcategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      image: image ?? this.image,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
