// lib/data/models/cart_models.dart
import 'package:yanzee_app/core/utils/parse.dart';

class CartItem {
  final String itemId; // use this id in PATCH /carts/items/:itemId
  final String variantId;
  final String productId;
  final String productName;
  final String? image;
  final String size;
  final int quantity;
  final double unitPrice; // normal price
  final double? discountPrice;
  final double effectivePrice; // what the customer pays per unit
  final double lineTotal;
  final int stock;
  final bool isSelected;
  final String? warning;

  const CartItem({
    required this.itemId,
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.image,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.discountPrice,
    required this.effectivePrice,
    required this.lineTotal,
    required this.stock,
    required this.isSelected,
    required this.warning,
  });

  bool get hasDiscount => effectivePrice < unitPrice;
  bool get canIncrease => quantity < stock;

  /// For the "3 item(s) left" label in the cart row.
  bool get isLowStock => stock > 0 && stock <= 5;

  /// Used for instant (optimistic) UI updates before the server answers.
  CartItem copyWith({int? quantity, bool? isSelected}) {
    final q = quantity ?? this.quantity;
    return CartItem(
      itemId: itemId,
      variantId: variantId,
      productId: productId,
      productName: productName,
      image: image,
      size: size,
      quantity: q,
      unitPrice: unitPrice,
      discountPrice: discountPrice,
      effectivePrice: effectivePrice,
      lineTotal: effectivePrice * q,
      stock: stock,
      isSelected: isSelected ?? this.isSelected,
      warning: warning,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      itemId: (json['itemId'] ?? '').toString(),
      variantId: (json['variantId'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      image: json['image']?.toString(),
      size: (json['size'] ?? '').toString(),
      quantity: parseInt(json['quantity'], 1),
      unitPrice: parseDouble(json['unitPrice']),
      discountPrice: parseDoubleOrNull(json['discountPrice']),
      effectivePrice: parseDouble(json['effectivePrice']),
      lineTotal: parseDouble(json['lineTotal']),
      stock: parseInt(json['stock']),
      isSelected: json['isSelected'] == true,
      warning: json['warning']?.toString(),
    );
  }
}

class CartShop {
  final String shopId;
  final String shopName;
  final List<CartItem> items;
  final double shopSubtotal;

  const CartShop({
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.shopSubtotal,
  });

  bool get allSelected => items.isNotEmpty && items.every((i) => i.isSelected);

  /// Same shop with a new list of items (subtotal recalculated).
  CartShop withItems(List<CartItem> newItems) {
    return CartShop(
      shopId: shopId,
      shopName: shopName,
      items: newItems,
      shopSubtotal: newItems
          .where((i) => i.isSelected)
          .fold<double>(0, (sum, i) => sum + i.lineTotal),
    );
  }

  factory CartShop.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return CartShop(
      shopId: (json['shopId'] ?? '').toString(),
      shopName: (json['shopName'] ?? '').toString(),
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(CartItem.fromJson)
              .toList()
          : <CartItem>[],
      shopSubtotal: parseDouble(json['shopSubtotal']),
    );
  }
}

class CartData {
  final List<CartShop> shops;
  final int selectedCount; // total quantity of the selected items
  final int totalItems; // total quantity of all items
  final double grandTotal; // total of the selected items

  const CartData({
    required this.shops,
    required this.selectedCount,
    required this.totalItems,
    required this.grandTotal,
  });

  static const empty = CartData(
    shops: [],
    selectedCount: 0,
    totalItems: 0,
    grandTotal: 0,
  );

  Iterable<CartItem> get items => shops.expand((s) => s.items);

  /// Number of rows, for "SELECT ALL (2 ITEM(S))".
  int get lineCount => items.length;

  bool get isEmpty => lineCount == 0;

  bool get allSelected => items.isNotEmpty && items.every((i) => i.isSelected);

  bool containsProduct(String productId) =>
      items.any((i) => i.productId == productId);

  /// Builds a CartData from shops and works out the totals itself.
  factory CartData.fromShops(List<CartShop> shops) {
    final all = shops.expand((s) => s.items);
    return CartData(
      shops: shops,
      selectedCount: all
          .where((i) => i.isSelected)
          .fold<int>(0, (sum, i) => sum + i.quantity),
      totalItems: all.fold<int>(0, (sum, i) => sum + i.quantity),
      grandTotal: all
          .where((i) => i.isSelected)
          .fold<double>(0, (sum, i) => sum + i.lineTotal),
    );
  }

  /// Returns a copy where every item went through [transform], with the
  /// totals recalculated. Used for instant UI updates; the real numbers
  /// from the server replace this right after.
  CartData mapItems(CartItem Function(CartShop shop, CartItem item) transform) {
    return CartData.fromShops(
      shops
          .map((shop) => shop.withItems(
                shop.items.map((i) => transform(shop, i)).toList(),
              ))
          .toList(),
    );
  }

  /// Returns a copy without the items whose itemId is in [itemIds].
  /// Shops that end up empty disappear.
  CartData removeItems(Set<String> itemIds) {
    final newShops = <CartShop>[];
    for (final shop in shops) {
      final kept =
          shop.items.where((i) => !itemIds.contains(i.itemId)).toList();
      if (kept.isNotEmpty) newShops.add(shop.withItems(kept));
    }
    return CartData.fromShops(newShops);
  }

  factory CartData.fromJson(Map<String, dynamic> json) {
    final rawShops = json['shops'];
    return CartData(
      shops: rawShops is List
          ? rawShops
              .whereType<Map<String, dynamic>>()
              .map(CartShop.fromJson)
              .toList()
          : <CartShop>[],
      selectedCount: parseInt(json['selectedCount']),
      totalItems: parseInt(json['totalItems']),
      grandTotal: parseDouble(json['grandTotal']),
    );
  }
}