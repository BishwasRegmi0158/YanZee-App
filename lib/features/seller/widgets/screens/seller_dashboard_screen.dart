import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/features/seller/widgets/chart_card.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_dashboard_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_dashboard_visit_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_store_provider.dart';
import 'package:yanzee_app/features/seller/widgets/stat_card.dart';
import 'package:yanzee_app/features/seller/widgets/recent_orders_card.dart';
import 'package:yanzee_app/features/seller/widgets/order_detail_sheet.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(sellerDashboardProvider);
    final store = ref.watch(sellerStoreProvider); // NEW: live store data
    final visitCount = ref.watch(sellerDashboardVisitProvider); // NEW: bumps on tab revisit

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (err, _) =>
              Center(child: Text('Failed to load dashboard: $err')),
          data: (stats) => ListView(
            key: ValueKey(visitCount), // NEW: forces rebuild -> replays chart animations
            padding: const EdgeInsets.all(16),
            children: [
              _Header(
                storeName: store.name, // NEW: reactive instead of hardcoded
                onBuyerView: () => context.go('/home'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Total Revenue',
                      value: 'Rs ${stats.totalRevenue.toStringAsFixed(0)}',
                      subtext: '+${stats.revenueMoMPercent}% MoM',
                      subtextColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Total Orders',
                      value: '${stats.totalOrders}',
                      subtext: '${stats.ordersAwaitingAction} awaiting action',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Products',
                      value: '${stats.totalProducts}',
                      subtext: '${stats.activeProducts} active',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Avg Order Value',
                      value: 'Rs ${stats.avgOrderValue.toStringAsFixed(0)}',
                      subtext: 'per checkout',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ChartCard(
                title: 'Revenue trend',
                subtitle: 'Monthly net revenue · Rs',
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= stats.revenueTrend.length)
                              return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                stats.revenueTrend[i].month,
                                // was fontSize 10, AppColors.textGray — too
                                // faint to read comfortably.
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink.withOpacity(0.55),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      getTouchedSpotIndicator: (barData, spotIndexes) {
                        return spotIndexes.map((index) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: AppColors.gold,
                              strokeWidth: 1.5,
                              dashArray: [4, 4],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) =>
                                  FlDotCirclePainter(
                                    radius: 5,
                                    color: AppColors.gold,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                            ),
                          );
                        }).toList();
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => AppColors.ink,
                        tooltipBorderRadius: BorderRadius.circular(10),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final i = spot.x.toInt();
                            final month =
                                (i >= 0 && i < stats.revenueTrend.length)
                                ? stats.revenueTrend[i].month
                                : '';
                            return LineTooltipItem(
                              '$month\n',
                              const TextStyle(
                                color: AppColors.textGray,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Rs ${_formatNepaliStyle(spot.y)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: AppColors.gold,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.gold.withOpacity(0.12),
                        ),
                        spots: [
                          for (var i = 0; i < stats.revenueTrend.length; i++)
                            FlSpot(i.toDouble(), stats.revenueTrend[i].value),
                        ],
                      ),
                    ],
                  ),
                  key: ValueKey('revenue-chart-$visitCount'),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutCubic,
                ),
              ),
              const SizedBox(height: 16),
              ChartCard(
                title: 'Monthly orders',
                subtitle: 'Orders placed per month',
                child: BarChart(
                  BarChartData(
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= stats.monthlyOrders.length)
                              return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                stats.monthlyOrders[i].month,
                                // was fontSize 10, AppColors.textGray — too
                                // faint to read comfortably.
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink.withOpacity(0.55),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // NEW: clean tooltip matching the revenue chart, instead
                    // of fl_chart's default plain gray box.
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => AppColors.ink,
                        tooltipBorderRadius: BorderRadius.circular(10),
                        tooltipMargin: 8,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final i = group.x;
                          final month = (i >= 0 && i < stats.monthlyOrders.length)
                              ? stats.monthlyOrders[i].month
                              : '';
                          final count = rod.toY.round();
                          return BarTooltipItem(
                            '$month\n',
                            const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: '$count ${count == 1 ? 'order' : 'orders'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < stats.monthlyOrders.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: stats.monthlyOrders[i].value,
                              color: AppColors.ink,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              RecentOrdersCard(
                orders: stats.recentOrders,
                totalCount: stats.totalOrders,
                onOrderTap: (order) => showOrderDetailSheet(context, ref, order),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String storeName; // NEW
  final VoidCallback onBuyerView;
  const _Header({required this.storeName, required this.onBuyerView});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded( // NEW: prevents long store names from overflowing the row
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELLER STUDIO',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                storeName, // was the hardcoded 'YanZee Atelier'
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.brand,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onBuyerView,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.gold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(
            Iconsax.shop, // was Icons.storefront_outlined
            size: 16,
            color: AppColors.gold,
          ),
          label: const Text('Buyer view'),
        ),
      ],
    );
  }
}

// Top-level helper — used by the revenue chart tooltip above
String _formatNepaliStyle(double value) {
  final n = value.round().toString();
  if (n.length <= 3) return n;
  final last3 = n.substring(n.length - 3);
  final rest = n.substring(0, n.length - 3);
  final regex = RegExp(r'(\d)(?=(\d{2})+(?!\d))');
  final formattedRest = rest.replaceAllMapped(regex, (m) => '${m[1]},');
  return '$formattedRest,$last3';
}