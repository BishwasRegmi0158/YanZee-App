import 'package:flutter/foundation.dart';

/// Order data as it actually flows in this app: it starts empty and
/// grows only when a real order is placed — nothing here is seeded or
/// hardcoded. Call `OrdersState.instance.addOrder(...)` from wherever
/// checkout completes (there's no checkout code in this session, so
/// that call site isn't wired up yet — this just gives My Orders a
/// real, listenable place to read from instead of a static list).
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.date,
    required this.itemCount,
    required this.total,
    required this.status,
  });

  final String id;
  final String date;
  final int itemCount;
  final double total;
  final String status; // 'Delivered' | 'In transit' | 'Processing'
}

class OrdersState extends ChangeNotifier {
  OrdersState._();
  static final OrdersState instance = OrdersState._();

  final List<OrderSummary> _orders = [];

  List<OrderSummary> get orders => List.unmodifiable(_orders);

  void addOrder(OrderSummary order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void updateStatus(String orderId, String status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final old = _orders[index];
    _orders[index] = OrderSummary(
      id: old.id,
      date: old.date,
      itemCount: old.itemCount,
      total: old.total,
      status: status,
    );
    notifyListeners();
  }

  void clear() {
    _orders.clear();
    notifyListeners();
  }
}