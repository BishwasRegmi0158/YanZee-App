import 'package:yanzee_app/data/models/sale_item.dart';
import 'package:yanzee_app/data/models/store_order.dart';

/// One product line while an order is being built or edited.
class DraftLine {
  DraftLine({
    required this.productId,
    required this.variantId,
    required this.name,
    required this.image,
    required this.sku,
    required this.unitPrice,
    required this.stock,
    this.quantity = 1,
    this.discountType = 'FIXED', // FIXED or PERCENT
    this.discountValue = 0,
  });

  factory DraftLine.fromSale(SaleItem i) => DraftLine(
        productId: i.productId,
        variantId: i.variantId,
        name: i.name,
        image: i.image,
        sku: i.sku,
        unitPrice: i.unitPrice,
        stock: i.quantity,
      );

  /// A line of an existing order. Its stock is unknown, so it is not limited.
  factory DraftLine.fromOrderLine(StoreOrderLine l) => DraftLine(
        productId: l.productId,
        variantId: l.variantId,
        name: l.name,
        image: l.image,
        sku: l.sku,
        unitPrice: l.unitPrice,
        stock: 1 << 30,
        quantity: l.quantity,
        discountType: l.discountType == 'PERCENT' ? 'PERCENT' : 'FIXED',
        discountValue: l.discountAmount > 0 ? l.discountValue : 0,
      );

  final String productId;
  final String? variantId;
  final String name;
  final String? image;
  final String? sku;
  final double unitPrice;
  final int stock;
  int quantity;
  String discountType;
  double discountValue;

  String get key => '$productId|${variantId ?? ''}';
  double get gross => unitPrice * quantity;

  double get discountAmount {
    if (discountValue <= 0) return 0;
    final d = discountType == 'PERCENT' ? gross * discountValue / 100 : discountValue;
    return d > gross ? gross : d;
  }

  double get lineTotal => gross - discountAmount;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
        if (discountValue > 0)
          'discount': {'type': discountType, 'value': discountValue},
      };
}

/// An estimate shown while building an order. The server calculates the
/// final amounts.
class OrderEstimate {
  final double gross;
  final double itemDiscount;
  final double orderDiscount;
  final double delivery;
  final double total;

  const OrderEstimate({
    required this.gross,
    required this.itemDiscount,
    required this.orderDiscount,
    required this.delivery,
    required this.total,
  });

  factory OrderEstimate.of(
    List<DraftLine> lines, {
    required String discountType,
    required double discountValue,
    required double deliveryFee,
  }) {
    final gross = lines.fold<double>(0, (s, l) => s + l.gross);
    final itemDiscount = lines.fold<double>(0, (s, l) => s + l.discountAmount);
    final afterItems = gross - itemDiscount;
    var order = discountValue <= 0
        ? 0.0
        : (discountType == 'PERCENT'
            ? afterItems * discountValue / 100
            : discountValue);
    if (order > afterItems) order = afterItems;
    return OrderEstimate(
      gross: gross,
      itemDiscount: itemDiscount,
      orderDiscount: order,
      delivery: deliveryFee,
      total: afterItems - order + deliveryFee,
    );
  }
}