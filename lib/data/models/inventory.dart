double _d(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
String? _s(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Quantity of one stock row inside one outlet.
class StockOutletQty {
  final String outletId;
  final String outletName;
  final int quantity;
  final int batchCount;
  final double totalCost;

  const StockOutletQty({
    required this.outletId,
    required this.outletName,
    required this.quantity,
    required this.batchCount,
    required this.totalCost,
  });

  factory StockOutletQty.fromJson(Map<String, dynamic> json) => StockOutletQty(
        outletId: json['outletId']?.toString() ?? '',
        outletName: json['outletName']?.toString() ?? '',
        quantity: _i(json['quantity']),
        batchCount: _i(json['batchCount']),
        totalCost: _d(json['totalCost']),
      );
}

/// One row of GET /inventory/stock: a product, or one variant of a product.
class StockItem {
  final String productId;
  final String? variantId;
  final String name;
  final String? sku;
  final int quantity;
  final String status;
  final int batchCount;
  final double totalCost;
  final List<StockOutletQty> outlets;

  const StockItem({
    required this.productId,
    required this.variantId,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.status,
    required this.batchCount,
    required this.totalCost,
    required this.outlets,
  });

  /// Quantity in one outlet, or the total when [outletId] is null.
  int quantityAt(String? outletId) {
    if (outletId == null || outlets.isEmpty) return quantity;
    var n = 0;
    for (final o in outlets) {
      if (o.outletId == outletId) n += o.quantity;
    }
    return n;
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    final rawOutlets = json['outlets'];
    return StockItem(
      productId: json['productId']?.toString() ?? '',
      variantId: _s(json['variantId']),
      name: json['name']?.toString() ?? '',
      sku: _s(json['sku']),
      quantity: _i(json['quantity']),
      status: json['status']?.toString() ?? '',
      batchCount: _i(json['batchCount']),
      totalCost: _d(json['totalCost']),
      outlets: rawOutlets is List
          ? rawOutlets
              .whereType<Map<String, dynamic>>()
              .map(StockOutletQty.fromJson)
              .toList()
          : const [],
    );
  }
}

/// One product line inside a stock movement.
class MovementItem {
  final String? name;
  final String? productId;
  final String? variantId;
  final String? sku;
  final String? batchLabel;
  final DateTime? expiryDate;
  final int quantity;
  final double unitCost;

  const MovementItem({
    required this.name,
    required this.productId,
    required this.variantId,
    required this.sku,
    required this.batchLabel,
    required this.expiryDate,
    required this.quantity,
    required this.unitCost,
  });

  factory MovementItem.fromJson(Map<String, dynamic> json) {
    final joined = [_s(json['productName']), _s(json['variantName'])]
        .whereType<String>()
        .join(' — ');
    final batchNumber = json['batchNumber'];

    return MovementItem(
      name: _s(json['name']) ?? (joined.isEmpty ? null : joined),
      productId: _s(json['productId']),
      variantId: _s(json['variantId']),
      sku: _s(json['sku']),
      batchLabel: _s(json['batchLabel']) ??
          (batchNumber == null
              ? null
              : 'B-${_i(batchNumber).toString().padLeft(6, '0')}'),
      expiryDate: DateTime.tryParse(
        '${json['batchExpiryDate'] ?? json['expiryDate'] ?? ''}',
      ),
      quantity: _i(json['quantity']),
      unitCost: _d(json['unitCost']),
    );
  }
}

/// One entry of GET /inventory/movements.
class StockMovement {
  final String id;
  final String type;
  final String? outletId;
  final String? outletName;
  final String? performedBy;
  final String? referenceNumber;
  final String? supplierName;
  final String? note;
  final int totalProducts;
  final int totalQuantity;
  final double totalCost;
  final DateTime? createdAt;
  final List<MovementItem> items;

  const StockMovement({
    required this.id,
    required this.type,
    this.outletId,
    this.outletName,
    this.performedBy,
    this.referenceNumber,
    this.supplierName,
    this.note,
    required this.totalProducts,
    required this.totalQuantity,
    required this.totalCost,
    this.createdAt,
    this.items = const [],
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final outlet = json['outlet'];
    final by = json['performedBy'] ?? json['createdBy'];
    final rawItems = json['items'] ?? json['batches'] ?? json['lines'];

    return StockMovement(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'STOCK_IN',
      outletId: _s(json['outletId']) ?? (outlet is Map ? _s(outlet['id']) : null),
      outletName:
          (outlet is Map ? _s(outlet['name']) : null) ?? _s(json['outletName']),
      performedBy:
          by is Map ? _s(by['fullName'] ?? by['name']) : _s(by),
      referenceNumber: _s(json['referenceNumber']),
      supplierName: _s(json['supplierName']),
      note: _s(json['note']),
      totalProducts: _i(json['totalProducts']),
      totalQuantity: _i(json['totalQuantity']),
      totalCost: _d(json['totalValue'] ?? json['totalCost']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => MovementItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// One line of a stock-in request.
class StockInLine {
  final String productId;
  final String? variantId;
  final int quantity;
  final double unitCost;
  final String? supplierLot;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;

  const StockInLine({
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.unitCost,
    this.supplierLot,
    this.manufactureDate,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
        'unitCost': unitCost,
        'supplierLot': supplierLot,
        'manufactureDate':
            manufactureDate == null ? null : _ymd(manufactureDate!),
        'expiryDate': expiryDate == null ? null : _ymd(expiryDate!),
      };
}