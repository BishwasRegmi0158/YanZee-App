import 'package:flutter/foundation.dart';
import 'package:yanzee_app/core/utils/parse.dart';

//  Status 

enum ProductStatus { active, draft, archived }

extension ProductStatusX on ProductStatus {
  String get label => switch (this) {
        ProductStatus.active => 'Active',
        ProductStatus.draft => 'Draft',
        ProductStatus.archived => 'Archived',
      };

  /// The value the backend expects.
  String get apiValue => switch (this) {
        ProductStatus.active => 'ACTIVE',
        ProductStatus.draft => 'DRAFT',
        ProductStatus.archived => 'ARCHIVED',
      };
}

ProductStatus productStatusFromApi(String? raw) =>
    switch (raw?.toUpperCase()) {
      'DRAFT' => ProductStatus.draft,
      'ARCHIVED' => ProductStatus.archived,
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

//  Old category enum helpers 
// Products now use shop categories (categoryIds). These are kept only
// because PublicProduct (customer side) still calls categoryFromApi.

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

String _titleCase(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

//  Small helpers 

String? _str(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

List<String> _strList(dynamic v) => v is List
    ? v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
    : <String>[];

/// yyyy-MM-dd, the format the backend expects for releaseDate.
String _dateOnly(DateTime d) => d.toIso8601String().substring(0, 10);

//  Brand / category reference 

@immutable
class SellerRef {
  final String id;
  final String name;
  const SellerRef({required this.id, required this.name});

  factory SellerRef.fromJson(Map<String, dynamic> j) => SellerRef(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
      );
}

//  Variant 

@immutable
class SellerVariant {
  final String? id; // null = not saved yet
  final String name;
  final String size;
  final List<String> colorCodes;
  final double sellingPrice;
  final double? crossedPrice;
  final double? costPrice;
  final int quantity;
  final double? weight;
  final String? sku;
  final String? hsCode;
  final String? altBarcode;

  const SellerVariant({
    this.id,
    required this.name,
    required this.size,
    required this.sellingPrice,
    required this.quantity,
    this.colorCodes = const [],
    this.crossedPrice,
    this.costPrice,
    this.weight,
    this.sku,
    this.hsCode,
    this.altBarcode,
  });

  factory SellerVariant.fromJson(Map<String, dynamic> j) => SellerVariant(
        id: _str(j['id']),
        name: j['name']?.toString() ?? '',
        size: j['size']?.toString() ?? '',
        colorCodes: _strList(j['colorCodes']),
        sellingPrice: parseDouble(j['sellingPrice']),
        crossedPrice: parseDoubleOrNull(j['crossedPrice']),
        costPrice: parseDoubleOrNull(j['costPrice']),
        quantity: parseInt(j['quantity'] ?? j['stock']),
        weight: parseDoubleOrNull(j['weight']),
        sku: _str(j['sku']),
        hsCode: _str(j['hsCode']),
        altBarcode: _str(j['altBarcode']),
      );

  /// Optional fields are only sent when they have a value.
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'size': size,
        if (colorCodes.isNotEmpty) 'colorCodes': colorCodes,
        'sellingPrice': sellingPrice,
        if (crossedPrice != null) 'crossedPrice': crossedPrice,
        if (costPrice != null) 'costPrice': costPrice,
        'quantity': quantity,
        if (weight != null) 'weight': weight,
        if (sku != null) 'sku': sku,
        if (hsCode != null) 'hsCode': hsCode,
        if (altBarcode != null) 'altBarcode': altBarcode,
      };
}

//  Product 

class SellerProduct {
  final String id; // '' for a product that is not saved yet
  final String name;
  final String slug;
  final String channel;
  final ProductAudience audience;
  final ProductStatus status;
  final bool isAvailable;
  final bool hasVariants;

  final String? brandId;
  final String? brandName;
  final List<SellerRef> categories;
  final List<String> categoryIds;

  final String productDescription;
  final String longDescription;
  final List<String> imageUrls;
  final List<String> tags;
  final List<String> similarProductIds;
  final DateTime? releaseDate;

  final double sellingPrice;
  final double? crossedPrice;
  final double? costPrice;
  final int quantity;
  final double? weight;
  final String? sku;
  final String? hsCode;
  final String? altBarcode;

  final String? seoTitle;
  final String? seoDescription;
  final String? seoImage;

  final List<SellerVariant> variants;
  final int variantCount;
  final double? priceMin;
  final double? priceMax;
  final DateTime? createdAt;

  const SellerProduct({
    this.id = '',
    required this.name,
    this.slug = '',
    this.channel = 'WEBSITE',
    this.audience = ProductAudience.unisex,
    this.status = ProductStatus.active,
    this.isAvailable = true,
    this.hasVariants = false,
    this.brandId,
    this.brandName,
    this.categories = const [],
    this.categoryIds = const [],
    this.productDescription = '',
    this.longDescription = '',
    this.imageUrls = const [],
    this.tags = const [],
    this.similarProductIds = const [],
    this.releaseDate,
    this.sellingPrice = 0,
    this.crossedPrice,
    this.costPrice,
    this.quantity = 0,
    this.weight,
    this.sku,
    this.hsCode,
    this.altBarcode,
    this.seoTitle,
    this.seoDescription,
    this.seoImage,
    this.variants = const [],
    this.variantCount = 0,
    this.priceMin,
    this.priceMax,
    this.createdAt,
  });

  //  Getters other screens may still use 

  double get price => sellingPrice;
  String get description => productDescription;
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  bool get isActive => status == ProductStatus.active;
  String get category => categories.map((c) => c.name).join(', ');

  /// Total stock: sum of variants when they are loaded, else the product quantity.
  int get stock => variants.isNotEmpty
      ? variants.fold<int>(0, (sum, v) => sum + v.quantity)
      : quantity;

  List<String> get options => variants.map((v) => v.size).toList();
  String get optionLabel => 'Size';

  //  Parsing 

  /// Works for both the list item and GET /products/:id.
  factory SellerProduct.fromJson(Map<String, dynamic> j) {
    final variants = ((j['variants'] as List?) ?? const [])
        .whereType<Map>()
        .map((v) => SellerVariant.fromJson(Map<String, dynamic>.from(v)))
        .toList();

    final categories = ((j['categories'] as List?) ?? const [])
        .whereType<Map>()
        .map((c) => SellerRef.fromJson(Map<String, dynamic>.from(c)))
        .toList();

    final brand = j['brand'];
    final similar = j['similarProducts'] is List
        ? (j['similarProducts'] as List)
            .whereType<Map>()
            .map((m) => m['id']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
        : _strList(j['similarProductIds']);

    return SellerProduct(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      slug: j['slug']?.toString() ?? '',
      channel: _str(j['channel']) ?? 'WEBSITE',
      audience: productAudienceFromApi(j['audience']?.toString()),
      status: productStatusFromApi(j['status']?.toString()),
      isAvailable: j['isAvailable'] != false,
      hasVariants: j['hasVariants'] == true || variants.isNotEmpty,
      brandId: brand is Map ? _str(brand['id']) : null,
      brandName: brand is Map ? _str(brand['name']) : null,
      categories: categories,
      categoryIds: categories.map((c) => c.id).toList(),
      productDescription: j['productDescription']?.toString() ?? '',
      longDescription: j['longDescription']?.toString() ?? '',
      imageUrls: _strList(j['imageUrls']),
      tags: _strList(j['tags']),
      similarProductIds: similar,
      releaseDate: DateTime.tryParse(j['releaseDate']?.toString() ?? ''),
      sellingPrice: parseDouble(j['sellingPrice']),
      crossedPrice: parseDoubleOrNull(j['crossedPrice']),
      costPrice: parseDoubleOrNull(j['costPrice']),
      quantity: parseInt(j['quantity']),
      weight: parseDoubleOrNull(j['weight']),
      sku: _str(j['sku']),
      hsCode: _str(j['hsCode']),
      altBarcode: _str(j['altBarcode']),
      seoTitle: _str(j['seoTitle']),
      seoDescription: _str(j['seoDescription']),
      seoImage: _str(j['seoImage']),
      variants: variants,
      variantCount: parseInt(j['variantCount'], variants.length),
      priceMin: parseDoubleOrNull(j['priceMin']),
      priceMax: parseDoubleOrNull(j['priceMax']),
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
    );
  }

  //  Request bodies 
  // Optional fields are left out when empty. Each method matches one endpoint.

  /// PATCH /products/:id/general
  Map<String, dynamic> generalJson({List<String>? imageUrls}) => {
        'name': name,
        'audience': audience.apiValue,
        'isAvailable': isAvailable,
        if (brandId != null) 'brandId': brandId,
        'categoryIds': ([...categoryIds]..sort()),
        'productDescription': productDescription,
        if (longDescription.isNotEmpty) 'longDescription': longDescription,
        'imageUrls': imageUrls ?? this.imageUrls,
      };

  /// PATCH /products/:id/inventory
  /// With variants: only the variants array (saved ones carry their id).
  /// Without variants: the product-level price and stock fields.
  Map<String, dynamic> inventoryJson() {
    if (variants.isNotEmpty) {
      return {'variants': variants.map((v) => v.toJson()).toList()};
    }
    return {
      'sellingPrice': sellingPrice,
      if (crossedPrice != null) 'crossedPrice': crossedPrice,
      if (costPrice != null) 'costPrice': costPrice,
      'quantity': quantity,
      if (weight != null) 'weight': weight,
      if (sku != null) 'sku': sku,
      if (hsCode != null) 'hsCode': hsCode,
      if (altBarcode != null) 'altBarcode': altBarcode,
    };
  }

  /// PATCH /products/:id/custom
  Map<String, dynamic> customJson() => {
        'tags': tags,
        if (releaseDate != null) 'releaseDate': _dateOnly(releaseDate!),
        'similarProductIds': similarProductIds,
      };

  /// PATCH /products/:id/seo
  Map<String, dynamic> seoJson({String? image}) {
    final img = image ?? seoImage;
    return {
      if (seoTitle != null) 'seoTitle': seoTitle,
      if (seoDescription != null) 'seoDescription': seoDescription,
      if (img != null) 'seoImage': img,
    };
  }

  /// POST /products
  Map<String, dynamic> toCreateJson({required List<String> imageUrls}) => {
        'channel': channel,
        'status': status.apiValue,
        ...generalJson(imageUrls: imageUrls),
        ...inventoryJson(),
        if (tags.isNotEmpty) 'tags': tags,
        if (releaseDate != null) 'releaseDate': _dateOnly(releaseDate!),
        if (similarProductIds.isNotEmpty)
          'similarProductIds': similarProductIds,
      };

  SellerProduct copyWith({ProductStatus? status}) => SellerProduct(
        id: id,
        name: name,
        slug: slug,
        channel: channel,
        audience: audience,
        status: status ?? this.status,
        isAvailable: isAvailable,
        hasVariants: hasVariants,
        brandId: brandId,
        brandName: brandName,
        categories: categories,
        categoryIds: categoryIds,
        productDescription: productDescription,
        longDescription: longDescription,
        imageUrls: imageUrls,
        tags: tags,
        similarProductIds: similarProductIds,
        releaseDate: releaseDate,
        sellingPrice: sellingPrice,
        crossedPrice: crossedPrice,
        costPrice: costPrice,
        quantity: quantity,
        weight: weight,
        sku: sku,
        hsCode: hsCode,
        altBarcode: altBarcode,
        seoTitle: seoTitle,
        seoDescription: seoDescription,
        seoImage: seoImage,
        variants: variants,
        variantCount: variantCount,
        priceMin: priceMin,
        priceMax: priceMax,
        createdAt: createdAt,
      );
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