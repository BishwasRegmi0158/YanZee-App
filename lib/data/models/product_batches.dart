double _d(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
String? _s(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? [
        for (final e in v)
          if (e is Map) Map<String, dynamic>.from(e),
      ]
    : <Map<String, dynamic>>[];

class BatchStock {
  final int received;
  final int remaining;
  final int used;

  const BatchStock({
    required this.received,
    required this.remaining,
    required this.used,
  });

  factory BatchStock.fromJson(Map<String, dynamic> j) => BatchStock(
        received: _i(j['received']),
        remaining: _i(j['remaining']),
        used: _i(j['used']),
      );
}

/// One received lot of stock (for example B-000002).
class StockBatch {
  final String id;
  final int batchNumber;
  final String label;
  final String? outletName;
  final double unitCost;
  final double totalCost;
  final BatchStock stock;
  final DateTime? expiryDate;
  final DateTime? createdAt;

  const StockBatch({
    required this.id,
    required this.batchNumber,
    required this.label,
    required this.outletName,
    required this.unitCost,
    required this.totalCost,
    required this.stock,
    required this.expiryDate,
    required this.createdAt,
  });

  factory StockBatch.fromJson(Map<String, dynamic> j) => StockBatch(
        id: j['id']?.toString() ?? '',
        batchNumber: _i(j['batchNumber']),
        label: _s(j['batchLabel']) ?? 'Batch ${_i(j['batchNumber'])}',
        outletName: _s(_map(j['outlet'])['name']),
        unitCost: _d(j['unitCost']),
        totalCost: _d(j['totalCost']),
        stock: BatchStock.fromJson(_map(j['stock'])),
        expiryDate: DateTime.tryParse(j['expiryDate']?.toString() ?? ''),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      );
}

/// The batches of one variant (or of the product when it has no variants).
class VariantBatches {
  final String? variantId;
  final String name;
  final int batchCount;
  final int totalReceived;
  final int totalRemaining;
  final double totalCost;
  final List<StockBatch> batches;

  const VariantBatches({
    required this.variantId,
    required this.name,
    required this.batchCount,
    required this.totalReceived,
    required this.totalRemaining,
    required this.totalCost,
    required this.batches,
  });

  factory VariantBatches.fromJson(Map<String, dynamic> j) {
    final summary = _map(j['summary']);
    final batches = _maps(j['batches']).map(StockBatch.fromJson).toList();
    return VariantBatches(
      variantId: _s(j['variantId']),
      name: _s(j['name']) ?? _s(j['variantName']) ?? 'Product',
      batchCount: _i(summary['batchCount'] ?? batches.length),
      totalReceived: _i(summary['totalReceived']),
      totalRemaining: _i(summary['totalRemaining']),
      totalCost: _d(summary['totalCost']),
      batches: batches,
    );
  }
}

class ProductBatches {
  final String productId;
  final String productName;
  final bool hasVariants;
  final int variantCount;
  final int batchCount;
  final int totalReceived;
  final int totalRemaining;
  final double totalCost;
  final List<VariantBatches> variants;

  const ProductBatches({
    required this.productId,
    required this.productName,
    required this.hasVariants,
    required this.variantCount,
    required this.batchCount,
    required this.totalReceived,
    required this.totalRemaining,
    required this.totalCost,
    required this.variants,
  });

  factory ProductBatches.fromJson(Map<String, dynamic> j) {
    final item = _map(j['item']);
    final summary = _map(j['summary']);
    return ProductBatches(
      productId: item['productId']?.toString() ?? '',
      productName: _s(item['productName']) ?? '',
      hasVariants: item['hasVariants'] == true,
      variantCount: _i(summary['variantCount']),
      batchCount: _i(summary['batchCount']),
      totalReceived: _i(summary['totalReceived']),
      totalRemaining: _i(summary['totalRemaining']),
      totalCost: _d(summary['totalCost']),
      variants: _maps(j['variants']).map(VariantBatches.fromJson).toList(),
    );
  }
}