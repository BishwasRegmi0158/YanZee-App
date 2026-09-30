enum ProductStatus { active, draft, outOfStock }

extension ProductStatusX on ProductStatus {
  String get label => switch (this) {
        ProductStatus.active => 'Active',
        ProductStatus.draft => 'Draft',
        ProductStatus.outOfStock => 'Out of stock',
      };
}

const kSellerCategories = ['Fashion', 'Beauty', 'Fragrance', 'Accessories'];

// Decimal prices often arrive from the backend as strings ("149.99"),
// so handle both numbers and strings.
double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String _titleCase(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

class SellerProduct {
  final String id; // backend ids are UUID strings
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

  /// Backend product: { id, name, category, status, price, discountPrice,
  /// image, gallery, description, variants: [{ size, stock, sku }] }
  factory SellerProduct.fromJson(Map<String, dynamic> json) {
    final variants = (json['variants'] as List?) ?? const [];
    final stock = variants.fold<int>(
      0,
      (sum, v) => sum + (((v as Map)['stock'] as num?) ?? 0).toInt(),
    );
    final sizes = variants
        .map((v) => (v as Map)['size']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    final rawStatus = json['status']?.toString().toUpperCase();
    final status = (rawStatus == null || rawStatus == 'ACTIVE')
        ? (stock == 0 ? ProductStatus.outOfStock : ProductStatus.active)
        : ProductStatus.draft;

    return SellerProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _toDouble(json['price']),
      category: _titleCase(json['category']?.toString() ?? ''),
      imageUrl: json['image']?.toString() ?? '',
      stock: stock,
      status: status,
      description: json['description']?.toString() ?? '',
      options: sizes,
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