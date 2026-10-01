import 'package:flutter/foundation.dart';

//  Status 

enum ProductStatus { active, draft, outOfStock }

extension ProductStatusX on ProductStatus {
  String get label => switch (this) {
        ProductStatus.active => 'Active',
        ProductStatus.draft => 'Draft',
        ProductStatus.outOfStock => 'Out of stock',
      };

  /// The value the backend expects.
  String get apiValue => switch (this) {
        ProductStatus.active => 'ACTIVE',
        ProductStatus.draft => 'DRAFT',
        ProductStatus.outOfStock => 'OUT_OF_STOCK',
      };
}

ProductStatus productStatusFromApi(String? raw) =>
    switch (raw?.toUpperCase()) {
      'DRAFT' => ProductStatus.draft,
      'OUT_OF_STOCK' => ProductStatus.outOfStock,
      _ => ProductStatus.active,
    };

//  Audience 

enum ProductAudience { men, women, unisex, boy, girl, kidsUnisex }

extension ProductAudienceX on ProductAudience {
  String get label => switch (this) {
        ProductAudience.men => 'Men',
        ProductAudience.women => 'Women',
        ProductAudience.unisex => 'Unisex',
        ProductAudience.boy => 'Boy',
        ProductAudience.girl => 'Girl',
        ProductAudience.kidsUnisex => 'Kids unisex',
      };

  String get apiValue => switch (this) {
        ProductAudience.men => 'MEN',
        ProductAudience.women => 'WOMEN',
        ProductAudience.unisex => 'UNISEX',
        ProductAudience.boy => 'BOY',
        ProductAudience.girl => 'GIRL',
        ProductAudience.kidsUnisex => 'KIDS_UNISEX',
      };
}

ProductAudience productAudienceFromApi(String? raw) =>
    switch (raw?.toUpperCase()) {
      'MEN' => ProductAudience.men,
      'WOMEN' => ProductAudience.women,
      'BOY' => ProductAudience.boy,
      'GIRL' => ProductAudience.girl,
      'KIDS_UNISEX' => ProductAudience.kidsUnisex,
      _ => ProductAudience.unisex,
    };

//  Category 

// Names shown in the app. The backend enum is the uppercase version
// (e.g. "Home decor" is sent as HOME_DECOR).
const kSellerCategories = [
  'Fashion',
  'Sports',
  'Kids',
  'Beauty',
  'Outlet',
  'Premium',
  'Home decor',
];

String categoryToApi(String label) =>
    label.trim().toUpperCase().replaceAll(' ', '_');

String categoryFromApi(String api) => _titleCase(api.replaceAll('_', ' '));

// Decimal prices often arrive from the backend as strings ("149.99"),
// so handle both numbers and strings.
double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String _titleCase(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

//  Variant 

/// One purchasable option of a product: { size, stock, sku }.
@immutable
class SellerVariant {
  final String size;
  final int stock;
  final String sku;

  const SellerVariant({
    required this.size,
    required this.stock,
    required this.sku,
  });

  factory SellerVariant.fromJson(Map<String, dynamic> json) => SellerVariant(
        size: json['size']?.toString() ?? '',
        stock: (json['stock'] as num?)?.toInt() ??
            int.tryParse('${json['stock']}') ??
            0,
        sku: json['sku']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'size': size, 'stock': stock, 'sku': sku};
}

//  Product 

class SellerProduct {
  final String id; // backend ids are UUID strings ('' for a new draft)
  final String name;
  final double price;
  final double? discountPrice;
  final String category; // display name, e.g. "Home decor"
  final ProductAudience audience;
  final String imageUrl;
  final ProductStatus status;
  final String description;
  final List<SellerVariant> variants;

  /// Kept exactly as the backend sent it so editing never damages it.
  final List<dynamic> gallery;

  const SellerProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.status,
    this.discountPrice,
    this.audience = ProductAudience.unisex,
    this.imageUrl = '',
    this.description = '',
    this.variants = const [],
    this.gallery = const [],
  });

  bool get isActive => status == ProductStatus.active;

  /// Total stock across all variants.
  int get stock => variants.fold<int>(0, (sum, v) => sum + v.stock);

  /// Kept for older screens that still read these.
  List<String> get options => variants.map((v) => v.size).toList();
  String get optionLabel => 'Size';

  /// Backend product: { id, name, category, audience, status, price,
  /// discountPrice, image, gallery, description,
  /// variants: [{ size, stock, sku }] }
  factory SellerProduct.fromJson(Map<String, dynamic> json) {
    final variants = ((json['variants'] as List?) ?? const [])
        .whereType<Map>()
        .map((v) => SellerVariant.fromJson(Map<String, dynamic>.from(v)))
        .toList();

    return SellerProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _toDouble(json['price']),
      discountPrice:
          json['discountPrice'] == null ? null : _toDouble(json['discountPrice']),
      category: categoryFromApi(json['category']?.toString() ?? ''),
      audience: productAudienceFromApi(json['audience']?.toString()),
      imageUrl: json['image']?.toString() ?? '',
      status: productStatusFromApi(json['status']?.toString()),
      description: json['description']?.toString() ?? '',
      variants: variants,
      gallery: List<dynamic>.from((json['gallery'] as List?) ?? const []),
    );
  }

  /// Body for POST /products and PATCH /products/:id.
  Map<String, dynamic> toApiJson() => {
        'name': name,
        'category': categoryToApi(category),
        'audience': audience.apiValue,
        'status': status.apiValue,
        'price': price,
        if (discountPrice != null) 'discountPrice': discountPrice,
        'image': imageUrl.isEmpty ? null : imageUrl,
        'gallery': gallery,
        'description': description,
        'variants': variants.map((v) => v.toJson()).toList(),
      };

  SellerProduct copyWith({
    String? name,
    double? price,
    double? discountPrice,
    bool clearDiscount = false,
    String? category,
    ProductAudience? audience,
    String? imageUrl,
    ProductStatus? status,
    String? description,
    List<SellerVariant>? variants,
  }) {
    return SellerProduct(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      discountPrice: clearDiscount ? null : (discountPrice ?? this.discountPrice),
      category: category ?? this.category,
      audience: audience ?? this.audience,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      description: description ?? this.description,
      variants: variants ?? this.variants,
      gallery: gallery,
    );
  }
}

//  Order (unchanged) 

class SellerOrder {
  final String id;
  final String customerName;
  final DateTime date;
  final int itemCount;
  final double total;
  final String status;
  final String productName;
  final String productImageUrl;
  final String paymentMethod; // placeholder until backend provides real payment data

  const SellerOrder({
    required this.id,
    required this.customerName,
    required this.date,
    required this.itemCount,
    required this.total,
    required this.status,
    this.productName = '',
    this.productImageUrl = '',
    this.paymentMethod = 'Cash on Delivery',
  });

  SellerOrder copyWith({
    String? status,
    String? productName,
    String? productImageUrl,
    String? paymentMethod,
  }) =>
      SellerOrder(
        id: id,
        customerName: customerName,
        date: date,
        itemCount: itemCount,
        total: total,
        status: status ?? this.status,
        productName: productName ?? this.productName,
        productImageUrl: productImageUrl ?? this.productImageUrl,
        paymentMethod: paymentMethod ?? this.paymentMethod,
      );
}