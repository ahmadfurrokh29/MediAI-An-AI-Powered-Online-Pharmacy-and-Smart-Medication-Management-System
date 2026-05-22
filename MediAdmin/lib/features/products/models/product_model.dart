import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String
  formulaName; // Medicine formula/generic name (required for Medicine category)
  final String description;
  final double price;
  final double salePrice;
  final int stock;
  final List<String> images;
  final List<String> imagePublicIds; // Cloudinary public_ids for deletion
  final String categoryId;
  final String categoryName;
  final String subcategoryId;
  final String subcategoryName;
  final String brandId;
  final String brandName;
  final bool isFeatured; // For popular products in category
  final bool isRecommended; // For recommended products shown per category
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.formulaName,
    required this.description,
    required this.price,
    required this.salePrice,
    required this.stock,
    required this.images,
    required this.imagePublicIds,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.brandId,
    required this.brandName,
    required this.isFeatured,
    required this.isRecommended,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create empty/new product
  static ProductModel empty() => ProductModel(
    id: '',
    name: '',
    formulaName: '',
    description: '',
    price: 0.0,
    salePrice: 0.0,
    stock: 0,
    images: [],
    imagePublicIds: [],
    categoryId: '',
    categoryName: '',
    subcategoryId: '',
    subcategoryName: '',
    brandId: '',
    brandName: '',
    isFeatured: false,
    isRecommended: false,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'FormulaName': formulaName,
      'Description': description,
      'Price': price,
      'SalePrice': salePrice,
      'Stock': stock,
      'Images': images,
      'ImagePublicIds': imagePublicIds,
      'CategoryId': categoryId,
      'CategoryName': categoryName,
      'SubcategoryId': subcategoryId,
      'SubcategoryName': subcategoryName,
      'BrandId': brandId,
      'BrandName': brandName,
      'IsFeatured': isFeatured,
      'IsRecommended': isRecommended,
      'IsActive': isActive,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
    };
  }

  // Create from Firestore snapshot
  factory ProductModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return ProductModel(
      id: document.id,
      name: data['Name'] ?? '',
      formulaName: data['FormulaName'] ?? '',
      description: data['Description'] ?? '',
      price: (data['Price'] ?? 0).toDouble(),
      salePrice: (data['SalePrice'] ?? 0).toDouble(),
      stock: data['Stock'] ?? 0,
      images: List<String>.from(data['Images'] ?? []),
      imagePublicIds: List<String>.from(data['ImagePublicIds'] ?? []),
      categoryId: data['CategoryId'] ?? '',
      categoryName: data['CategoryName'] ?? '',
      subcategoryId: data['SubcategoryId'] ?? '',
      subcategoryName: data['SubcategoryName'] ?? '',
      brandId: data['BrandId'] ?? '',
      brandName: data['BrandName'] ?? '',
      isFeatured: data['IsFeatured'] ?? false,
      isRecommended: data['IsRecommended'] ?? false,
      isActive: data['IsActive'] ?? true,
      createdAt: (data['CreatedAt'] as Timestamp).toDate(),
      updatedAt: (data['UpdatedAt'] as Timestamp).toDate(),
    );
  }

  // CopyWith method
  ProductModel copyWith({
    String? id,
    String? name,
    String? formulaName,
    String? description,
    double? price,
    double? salePrice,
    int? stock,
    List<String>? images,
    List<String>? imagePublicIds,
    String? categoryId,
    String? categoryName,
    String? subcategoryId,
    String? subcategoryName,
    String? brandId,
    String? brandName,
    bool? isFeatured,
    bool? isRecommended,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      formulaName: formulaName ?? this.formulaName,
      description: description ?? this.description,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      imagePublicIds: imagePublicIds ?? this.imagePublicIds,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      isFeatured: isFeatured ?? this.isFeatured,
      isRecommended: isRecommended ?? this.isRecommended,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
