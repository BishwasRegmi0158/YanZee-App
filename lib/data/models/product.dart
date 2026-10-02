// lib/data/models/product.dart
import 'package:yanzee_app/core/utils/parse.dart';

class ProductVariant {
  final String id;
  final String size;
  final int stock;
  final String? sku;

  const ProductVariant({
    required this.id,
    required this.size,
    required this.stock,
    this.sku,
  });

  bool get inStock => stock > 0;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: (json['id'] ?? '').toString(),
      size: (json['size'] ?? '').toString(),
      stock: parseInt(json['stock']),
      sku: json['sku']?.toString(),
    );
  }
}

class Product {
  final String id; // UUID
  final String shopId;
  final String name;
  final String category; // backend enum, e.g. HOME_DECOR
  final String status; // ACTIVE / DRAFT / OUT_OF_STOCK
  final String audience; // MEN / WOMEN / ...
  final String imageUrl; // '' when the product has no cover image
  final List<String> gallery;
  final int totalStock;

  /// Backend `price` (the normal price).
  final double originalPrice;

  /// Backend `discountPrice` (the sale price), null when there is no discount.
  final double? salePrice;

  /// Only present when the product comes from GET /products/:id.
  final String? description;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.category,
    required this.status,
    required this.audience,
    required this.imageUrl,
    required this.gallery,
    required this.totalStock,
    required this.originalPrice,
    required this.salePrice,
    required this.variants,
    this.description,
  });

  bool get hasDiscount =>
      salePrice != null && salePrice! > 0 && salePrice! < originalPrice;

  /// The price the customer actually pays.
  double get price => hasDiscount ? salePrice! : originalPrice;

  double get discountPercentage =>
      hasDiscount ? (1 - salePrice! / originalPrice) * 100 : 0;

  bool get inStock => totalStock > 0;

  List<String> get images => [if (imageUrl.isNotEmpty) imageUrl, ...gallery];

  List<ProductVariant> get availableVariants =>
      variants.where((v) => v.inStock).toList();

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variants'];
    final variants = rawVariants is List
        ? rawVariants
            .whereType<Map<String, dynamic>>()
            .map(ProductVariant.fromJson)
            .toList()
        : <ProductVariant>[];

    final rawGallery = json['gallery'];

    return Product(
      id: (json['id'] ?? '').toString(),
      shopId: (json['shopId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      audience: (json['audience'] ?? '').toString(),
      imageUrl: (json['image'] ?? '').toString(),
      gallery: rawGallery is List
          ? rawGallery.map((e) => e.toString()).toList()
          : <String>[],
      totalStock: json['totalStock'] != null
          ? parseInt(json['totalStock'])
          : variants.fold<int>(0, (sum, v) => sum + v.stock),
      originalPrice: parseDouble(json['price']),
      salePrice: parseDoubleOrNull(json['discountPrice']),
      description: json['description']?.toString(),
      variants: variants,
    );
  }
}