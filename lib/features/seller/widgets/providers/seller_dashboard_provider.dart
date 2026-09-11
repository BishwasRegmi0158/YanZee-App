import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/dashboard_stats.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_orders_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_products_provider.dart';

const _monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

final sellerDashboardProvider = FutureProvider<DashboardStats>((ref) async {
  final products = await ref.watch(sellerProductsProvider.future);
  final orders = await ref.watch(sellerOrdersProvider.future);

  final activeProducts = products.where((p) => p.isActive).length;
  final awaitingAction = orders.where((o) => o.status == 'New' || o.status == 'Processing').length;
  final validOrders = orders.where((o) => o.status != 'Declined').toList();

  final totalRevenue = validOrders.fold<double>(0, (sum, o) => sum + o.total);
  final avgOrderValue = validOrders.isEmpty ? 0.0 : totalRevenue / validOrders.length;

  // Group revenue + order count by calendar month, across the last 9 months.
  final now = DateTime.now();
  final months = List.generate(9, (i) {
    final d = DateTime(now.year, now.month - (8 - i));
    return _monthNames[d.month - 1];
  });

  final revenueByMonth = {for (final m in months) m: 0.0};
  final ordersByMonth = {for (final m in months) m: 0.0};

  for (final o in validOrders) {
    final label = _monthNames[o.date.month - 1];
    if (revenueByMonth.containsKey(label)) {
      revenueByMonth[label] = revenueByMonth[label]! + o.total;
      ordersByMonth[label] = ordersByMonth[label]! + 1;
    }
  }

  // Simple MoM: compare last two populated months.
  final revenueValues = months.map((m) => revenueByMonth[m]!).toList();
  final momPercent = revenueValues.length >= 2 && revenueValues[revenueValues.length - 2] > 0
      ? ((revenueValues.last - revenueValues[revenueValues.length - 2]) / revenueValues[revenueValues.length - 2]) * 100
      : 0.0;

  // NEW: most recent orders, newest first, capped to 4 for the dashboard preview card.
  final recentOrders = [...validOrders]..sort((a, b) => b.date.compareTo(a.date));
  final recentOrdersPreview = recentOrders.take(4).toList();

  return DashboardStats(
    totalRevenue: totalRevenue,
    revenueMoMPercent: double.parse(momPercent.toStringAsFixed(1)),
    totalOrders: orders.length,
    ordersAwaitingAction: awaitingAction,
    totalProducts: products.length,
    activeProducts: activeProducts,
    avgOrderValue: avgOrderValue,
    revenueTrend: [for (final m in months) MonthlyPoint(m, revenueByMonth[m]!)],
    monthlyOrders: [for (final m in months) MonthlyPoint(m, ordersByMonth[m]!)],
    recentOrders: recentOrdersPreview, // NEW
  );
});