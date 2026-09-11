

enum ProductStatus { active, draft, outOfStock }

extension ProductStatusX on ProductStatus {
  String get label => switch (this) {
        ProductStatus.active => 'Active',
        ProductStatus.draft => 'Draft',
        ProductStatus.outOfStock => 'Out of stock',
      };
}

const kSellerCategories = ['Fashion', 'Beauty', 'Fragrance', 'Accessories'];


String _mapToSellerCategory(String rawCategory) {
  final c = rawCategory.toLowerCase();

  if (c.contains('fragrance')) return 'Fragrance';
  if (c.contains('beauty') || c.contains('skin')) return 'Beauty';
  if (c.contains('watch') || c.contains('bag') || c.contains('jewel') || c.contains('sunglass')) {
    return 'Accessories';
  }
  if (c.contains('shirt') ||
      c.contains('dress') ||
      c.contains('shoe') ||
      c.contains('top') ||
      c.contains('mens') ||
      c.contains('womens')) {
    return 'Fashion';
  }

  return 'Fashion';
}

class SellerProduct {
  final int id;
  final String name;
  final double price;
  final String category;
  final String imageUrl;
  final int stock;
  final ProductStatus status;
  final String description;
  final String optionLabel;
  final List<String> options;

  const SellerProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.stock,
    required this.status,
    this.description = '',
    this.optionLabel = 'Size',
    this.options = const [],
  });

  
  bool get isActive => status == ProductStatus.active;

  factory SellerProduct.fromJson(Map<String, dynamic> json) {
    final stock = (json['stock'] ?? 0) as int;
    return SellerProduct(
      id: json['id'] ?? 0,
      name: json['title'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: _mapToSellerCategory(json['category'] ?? ''),
      imageUrl: json['thumbnail'] ?? '',
      stock: stock,
      status: stock == 0 ? ProductStatus.outOfStock : ProductStatus.active,
      description: json['description'] ?? '',
    );
  }

  SellerProduct copyWith({
    String? name,
    double? price,
    String? category,
    String? imageUrl,
    int? stock,
    ProductStatus? status,
    String? description,
    String? optionLabel,
    List<String>? options,
  }) {
    return SellerProduct(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      description: description ?? this.description,
      optionLabel: optionLabel ?? this.optionLabel,
      options: options ?? this.options,
    );
  }
}

class SellerOrder {
  final String id;
  final String customerName;
  final DateTime date;
  final int itemCount;
  final double total;
  final String status; 
  final String productName;
  final String productImageUrl;

  const SellerOrder({
    required this.id,
    required this.customerName,
    required this.date,
    required this.itemCount,
    required this.total,
    required this.status,
    this.productName = '',
    this.productImageUrl = '',
  });

  SellerOrder copyWith({
    String? status,
    String? productName,
    String? productImageUrl,
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
      );
}