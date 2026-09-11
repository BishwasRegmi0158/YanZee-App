import 'package:yanzee_app/data/models/seller_models.dart';

class MonthlyPoint {
  final String month;
  final double value;
  const MonthlyPoint(this.month, this.value);
}

class DashboardStats {
  final double totalRevenue;
  final double revenueMoMPercent;
  final int totalOrders;
  final int ordersAwaitingAction;
  final int totalProducts;
  final int activeProducts;
  final double avgOrderValue;
  final List<MonthlyPoint> revenueTrend;
  final List<MonthlyPoint> monthlyOrders;
  final List<SellerOrder> recentOrders;

  const DashboardStats({
    required this.totalRevenue,
    required this.revenueMoMPercent,
    required this.totalOrders,
    required this.ordersAwaitingAction,
    required this.totalProducts,
    required this.activeProducts,
    required this.avgOrderValue,
    required this.revenueTrend,
    required this.monthlyOrders,
    required this.recentOrders,
  });
}