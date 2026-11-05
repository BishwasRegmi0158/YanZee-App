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

/// PARTIAL_PAID -> Partial paid
String prettyEnum(String raw) {
  final words = raw
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w.toLowerCase())
      .toList();
  if (words.isEmpty) return raw;
  return '${words.first[0].toUpperCase()}${words.first.substring(1)}'
      '${words.length > 1 ? ' ${words.skip(1).join(' ')}' : ''}';
}

/// An order moves step by step: PENDING, PROCESSING, DELIVERED.
/// It can be CANCELLED before delivery and RETURNED after delivery.
class StoreOrderStatus {
  StoreOrderStatus._();
  static const pending = 'PENDING';
  static const processing = 'PROCESSING';
  static const delivered = 'DELIVERED';
  static const cancelled = 'CANCELLED';
  static const returned = 'RETURNED';
  static const values = [pending, processing, delivered, cancelled, returned];
}

class StorePaymentStatus {
  StorePaymentStatus._();
  static const unpaid = 'UNPAID';
  static const partial = 'PARTIAL_PAID';
  static const paid = 'PAID';
  static const values = [unpaid, partial, paid];
}

class StoreOrderChannel {
  StoreOrderChannel._();
  static const admin = 'ADMIN';
  static const pos = 'POS';
  static const web = 'WEB';
}

class StorePaymentMethod {
  StorePaymentMethod._();
  static const cash = 'CASH';
  static const cod = 'COD';
  static const values = [cash, cod];
}

/// One row of GET /orders.
class StoreOrderRow {
  final String id;
  final int orderNumber;
  final String status;
  final String channel;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final int totalQuantity;
  final DateTime? createdAt;

  const StoreOrderRow({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.channel,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalQuantity,
    required this.createdAt,
  });

  factory StoreOrderRow.fromJson(Map<String, dynamic> j) => StoreOrderRow(
        id: j['id']?.toString() ?? '',
        orderNumber: _i(j['orderNumber']),
        status: _s(j['status']) ?? StoreOrderStatus.pending,
        channel: _s(j['channel']) ?? '',
        customerName: _s(j['customerName']) ?? 'Customer',
        customerPhone: _s(j['customerPhone']),
        customerEmail: _s(j['customerEmail']),
        total: _d(j['total']),
        paymentMethod: _s(j['paymentMethod']) ?? '',
        paymentStatus: _s(j['paymentStatus']) ?? StorePaymentStatus.unpaid,
        totalQuantity: _i(j['totalQuantity']),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      );
}

/// One product line of an order.
class StoreOrderLine {
  final String id;
  final String productId;
  final String? variantId;
  final String name;
  final String? sku;
  final String? image;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? discountType; // PERCENT or FIXED
  final double discountValue;
  final double discountAmount;
  final double lineTotal;
  final String? outletName;

  const StoreOrderLine({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.name,
    required this.sku,
    required this.image,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.lineTotal,
    required this.outletName,
  });

  factory StoreOrderLine.fromJson(Map<String, dynamic> j) {
    final d = _map(j['discount']);
    return StoreOrderLine(
      id: j['id']?.toString() ?? '',
      productId: j['productId']?.toString() ?? '',
      variantId: _s(j['variantId']),
      name: _s(j['name']) ?? _s(j['productName']) ?? 'Item',
      sku: _s(j['sku']),
      image: _s(j['image']),
      quantity: _i(j['quantity']),
      unitPrice: _d(j['unitPrice']),
      totalPrice: _d(j['totalPrice']),
      discountType: _s(d['type']),
      discountValue: _d(d['value']),
      discountAmount: _d(d['amount']),
      lineTotal: _d(j['lineTotal']),
      outletName: _s(_map(j['fulfilledFrom'])['name']),
    );
  }
}

/// The money part of an order.
class StoreOrderTotals {
  final List<StoreOrderLine> items;
  final int totalQuantity;
  final double subtotal;
  final double itemDiscount;
  final String? orderDiscountType;
  final double orderDiscountValue;
  final double orderDiscountAmount;
  final double deliveryFee;
  final double total;
  final double paidAmount;
  final double refundedAmount;

  const StoreOrderTotals({
    required this.items,
    required this.totalQuantity,
    required this.subtotal,
    required this.itemDiscount,
    required this.orderDiscountType,
    required this.orderDiscountValue,
    required this.orderDiscountAmount,
    required this.deliveryFee,
    required this.total,
    required this.paidAmount,
    required this.refundedAmount,
  });

  factory StoreOrderTotals.fromJson(Map<String, dynamic> j) {
    final od = _map(j['orderDiscount']);
    return StoreOrderTotals(
      items: _maps(j['items']).map(StoreOrderLine.fromJson).toList(),
      totalQuantity: _i(j['totalQuantity']),
      subtotal: _d(j['subtotal']),
      itemDiscount: _d(j['itemDiscount']),
      orderDiscountType: _s(od['type']),
      orderDiscountValue: _d(od['value']),
      orderDiscountAmount: _d(od['amount']),
      deliveryFee: _d(j['deliveryFee']),
      total: _d(j['total']),
      paidAmount: _d(j['paidAmount']),
      refundedAmount: _d(j['refundedAmount']),
    );
  }
}

class StoreOrderCustomer {
  final String? id;
  final String? name;
  final String? phone;
  final String? email;
  final String? province;
  final String? district;
  final String? city;
  final String? address;
  final String? landmark;
  final String? customerNote;
  final String? orderNote;
  final int totalOrders;
  final DateTime? customerSince;

  const StoreOrderCustomer({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.province,
    this.district,
    this.city,
    this.address,
    this.landmark,
    this.customerNote,
    this.orderNote,
    this.totalOrders = 0,
    this.customerSince,
  });

  /// shirjana chowk, Lakeside, Pokhara, Kaski, Gandaki
  String get fullAddress => [address, landmark, city, district, province]
      .whereType<String>()
      .join(', ');

  factory StoreOrderCustomer.fromJson(Map<String, dynamic> j) =>
      StoreOrderCustomer(
        id: _s(j['id']),
        name: _s(j['name']),
        phone: _s(j['phone']),
        email: _s(j['email']),
        province: _s(j['province']),
        district: _s(j['district']),
        city: _s(j['city']),
        address: _s(j['address']),
        landmark: _s(j['landmark']),
        customerNote: _s(j['customerNote']),
        orderNote: _s(j['orderNote']),
        totalOrders: _i(j['totalOrders']),
        customerSince: DateTime.tryParse(j['customerSince']?.toString() ?? ''),
      );
}

class StoreOrderActivity {
  final String id;
  final String title;
  final String? actorName;
  final String? actorRole;
  final DateTime? createdAt;

  const StoreOrderActivity({
    required this.id,
    required this.title,
    required this.actorName,
    required this.actorRole,
    required this.createdAt,
  });

  factory StoreOrderActivity.fromJson(Map<String, dynamic> j) =>
      StoreOrderActivity(
        id: j['id']?.toString() ?? '',
        title: _s(j['title']) ?? prettyEnum(j['action']?.toString() ?? ''),
        actorName: _s(j['actorName']),
        actorRole: _s(j['actorRole']),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      );
}

/// GET /orders/:id
class StoreOrderDetail {
  final String id;
  final int orderNumber;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String channel;
  final String? createdBy;
  final String? outletId;
  final String? outletName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final StoreOrderTotals summary;
  final StoreOrderCustomer customer;
  final List<StoreOrderActivity> activities;

  const StoreOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.channel,
    required this.createdBy,
    required this.outletId,
    required this.outletName,
    required this.createdAt,
    required this.updatedAt,
    required this.summary,
    required this.customer,
    required this.activities,
  });

  factory StoreOrderDetail.fromJson(Map<String, dynamic> j) {
    final placed = _map(j['placedAt']);
    final by = _map(j['createdBy']);
    return StoreOrderDetail(
      id: j['id']?.toString() ?? '',
      orderNumber: _i(j['orderNumber']),
      status: _s(j['status']) ?? StoreOrderStatus.pending,
      paymentStatus: _s(j['paymentStatus']) ?? StorePaymentStatus.unpaid,
      paymentMethod: _s(j['paymentMethod']) ?? '',
      channel: _s(j['channel']) ?? '',
      createdBy: _s(by['fullName'] ?? by['name']),
      outletId: _s(placed['id']),
      outletName: _s(placed['name']),
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(j['updatedAt']?.toString() ?? ''),
      summary: StoreOrderTotals.fromJson(_map(j['summary'])),
      customer: StoreOrderCustomer.fromJson(_map(j['customer'])),
      activities:
          _maps(j['activities']).map(StoreOrderActivity.fromJson).toList(),
    );
  }
}