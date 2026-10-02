import 'package:yanzee_app/data/models/seller_models.dart';

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class ProductVariant {
  final String id; // this is the variantId the cart API needs
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

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id']?.toString() ?? '',
        size: json['size']?.toString() ?? '',
        stock: (json['stock'] as num?)?.toInt() ?? int.tryParse('${json['stock']}') ?? 0,
        sku: json['sku']?.toString(),
      );
}

class PublicProduct {
  final String id;
  final String shopId;
  final String name;
  final String description; // empty in list responses
  final String category; // backend enum, e.g. HOME_DECOR
  final String audience; // backend enum, e.g. KIDS_UNISEX
  final String status;
  final String imageUrl;
  final List<dynamic> gallery;
  final double price; // original price
  final double? discountPrice; // the sale price, when there is one
  final int totalStock;
  final List<ProductVariant> variants;

  const PublicProduct({
    required this.id,
    required this.shopId,
    required this.name,
    required this.category,
    required this.audience,
    required this.status,
    required this.price,
    required this.totalStock,
    this.description = '',
    this.imageUrl = '',
    this.gallery = const [],
    this.discountPrice,
    this.variants = const [],
  });

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  /// What the customer actually pays.
  double get effectivePrice => hasDiscount ? discountPrice! : price;

  double get discountPercent =>
      hasDiscount && price > 0 ? (price - discountPrice!) / price * 100 : 0;

  bool get inStock => totalStock > 0;
  String get categoryLabel => categoryFromApi(category);
  String get audienceLabel => productAudienceFromApi(audience).label;

  factory PublicProduct.fromJson(Map<String, dynamic> json) {
    final variants = ((json['variants'] as List?) ?? const [])
        .whereType<Map>()
        .map((v) => ProductVariant.fromJson(Map<String, dynamic>.from(v)))
        .toList();

    return PublicProduct(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      audience: json['audience']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? '',
      gallery: List<dynamic>.from((json['gallery'] as List?) ?? const []),
      price: _num(json['price']),
      discountPrice:
          json['discountPrice'] == null ? null : _num(json['discountPrice']),
      totalStock: (json['totalStock'] as num?)?.toInt() ??
          variants.fold<int>(0, (s, v) => s + v.stock),
      variants: variants,
    );
  }
}