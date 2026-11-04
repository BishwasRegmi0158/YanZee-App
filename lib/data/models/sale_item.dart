double _d(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
String? _s(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// One sellable row (a product, or one variant) from GET /products/sellable-items.
class SaleItem {
  final String productId;
  final String? variantId;
  final String name;
  final String? sku;
  final String? image;
  final int quantity;
  final double unitPrice;

  const SaleItem({
    required this.productId,
    required this.variantId,
    required this.name,
    required this.sku,
    required this.image,
    required this.quantity,
    required this.unitPrice,
  });

  String get key => '$productId|${variantId ?? ''}';

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        productId: j['productId']?.toString() ?? '',
        variantId: _s(j['variantId']),
        name: _s(j['name']) ?? _s(j['productName']) ?? 'Item',
        sku: _s(j['sku']),
        image: _s(j['image']),
        quantity: _i(j['quantity']),
        unitPrice: _d(j['unitPrice']),
      );
}