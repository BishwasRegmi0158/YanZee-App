double _d(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
int? _iOrNull(dynamic v) =>
    v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
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

class OverviewValue {
  final double sellingValue;
  final double costValue;
  final double potentialProfit;
  final int totalProducts;
  final int totalQuantity;

  const OverviewValue({
    required this.sellingValue,
    required this.costValue,
    required this.potentialProfit,
    required this.totalProducts,
    required this.totalQuantity,
  });

  factory OverviewValue.fromJson(Map<String, dynamic> j) => OverviewValue(
        sellingValue: _d(j['sellingValue']),
        costValue: _d(j['costValue']),
        potentialProfit: _d(j['potentialProfit']),
        totalProducts: _i(j['totalProducts']),
        totalQuantity: _i(j['totalQuantity']),
      );
}

class OverviewHealth {
  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int lowStockThreshold;

  const OverviewHealth({
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.lowStockThreshold,
  });

  int get total => inStock + lowStock + outOfStock;

  factory OverviewHealth.fromJson(Map<String, dynamic> j) => OverviewHealth(
        inStock: _i(j['inStock']),
        lowStock: _i(j['lowStock']),
        outOfStock: _i(j['outOfStock']),
        lowStockThreshold: _i(j['lowStockThreshold']),
      );
}

/// One row of the fast-moving, expiring-soon or expired lists.
class OverviewItem {
  final String name;
  final String? sku;

  // fast moving
  final int unitsSold;
  final double sharePercent;
  final int currentQuantity;
  final int? daysOfStock;

  // expiring / expired
  final int units;
  final double costValue;
  final DateTime? nextExpiryDate;
  final int? daysLeft;

  const OverviewItem({
    required this.name,
    this.sku,
    this.unitsSold = 0,
    this.sharePercent = 0,
    this.currentQuantity = 0,
    this.daysOfStock,
    this.units = 0,
    this.costValue = 0,
    this.nextExpiryDate,
    this.daysLeft,
  });

  factory OverviewItem.fromJson(Map<String, dynamic> j) {
    final fallback = [_s(j['productName']), _s(j['variantName'])]
        .whereType<String>()
        .join(' — ');
    return OverviewItem(
      name: _s(j['name']) ?? (fallback.isEmpty ? 'Product' : fallback),
      sku: _s(j['sku']),
      unitsSold: _i(j['unitsSold']),
      sharePercent: _d(j['sharePercent']),
      currentQuantity: _i(j['currentQuantity']),
      daysOfStock: _iOrNull(j['daysOfStock']),
      units: _i(j['units']),
      costValue: _d(j['costValue']),
      nextExpiryDate: DateTime.tryParse(j['nextExpiryDate']?.toString() ?? ''),
      daysLeft: _iOrNull(j['daysLeft']),
    );
  }
}

/// A block of the movement section: fast moving, expiring soon or expired.
class OverviewGroup {
  final int days;
  final int itemCount;
  final int units;
  final double costValue;
  final List<OverviewItem> items;

  const OverviewGroup({
    required this.days,
    required this.itemCount,
    required this.units,
    required this.costValue,
    required this.items,
  });

  factory OverviewGroup.fastMoving(Map<String, dynamic> j) => OverviewGroup(
        days: _i(j['days']),
        itemCount: _i(j['movingItems']),
        units: _i(j['unitsSold']),
        costValue: 0,
        items: _maps(j['items']).map(OverviewItem.fromJson).toList(),
      );

  /// Used for both "expiring soon" and "expired".
  factory OverviewGroup.expiring(Map<String, dynamic> j) => OverviewGroup(
        days: _i(j['days']),
        itemCount: _i(j['items']),
        units: _i(j['units']),
        costValue: _d(j['costValue']),
        items: _maps(j['list']).map(OverviewItem.fromJson).toList(),
      );
}

class InventoryOverview {
  final String? scopeId;
  final String scopeName;
  final OverviewValue value;
  final OverviewHealth health;
  final OverviewGroup fastMoving;
  final OverviewGroup expiringSoon;
  final OverviewGroup expired;

  const InventoryOverview({
    required this.scopeId,
    required this.scopeName,
    required this.value,
    required this.health,
    required this.fastMoving,
    required this.expiringSoon,
    required this.expired,
  });

  factory InventoryOverview.fromJson(Map<String, dynamic> j) {
    final scope = _map(j['scope']);
    final movement = _map(j['movement']);
    return InventoryOverview(
      scopeId: _s(scope['id']),
      scopeName: _s(scope['name']) ?? 'All active outlets',
      value: OverviewValue.fromJson(_map(j['inventoryValue'])),
      health: OverviewHealth.fromJson(_map(j['health'])),
      fastMoving: OverviewGroup.fastMoving(_map(movement['fastMoving'])),
      expiringSoon: OverviewGroup.expiring(_map(movement['expiringSoon'])),
      expired: OverviewGroup.expiring(_map(movement['expired'])),
    );
  }
}