// features/seller/screens/seller_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/core/utils/currency_format.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/features/seller/widgets/chart_card.dart';
import 'package:yanzee_app/features/seller/widgets/monthly_orders_bar_chart.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_dashboard_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_dashboard_visit_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_store_provider.dart';
import 'package:yanzee_app/features/seller/widgets/revenue_line_chart.dart';
import 'package:yanzee_app/features/seller/widgets/stat_card.dart';
import 'package:yanzee_app/features/seller/widgets/recent_orders_card.dart';
import 'package:yanzee_app/features/seller/widgets/order_detail_sheet.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(sellerDashboardProvider);
    final store = ref.watch(sellerStoreProvider);
    final visitCount = ref.watch(sellerDashboardVisitProvider);

    final isNarrow = Responsive.isSmallPhone(context);

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
            key: ValueKey(visitCount),
            padding: const EdgeInsets.all(16),
            children: [
              _Header(
                storeName: store.name,
                onBuyerView: () => context.go('/home'),
              ),
              const SizedBox(height: 20),
              _StatRow(
                isNarrow: isNarrow,
                left: StatCard(
                  label: 'Total Revenue',
                  value: 'Rs ${formatNepaliStyle(stats.totalRevenue)}',
                  subtext: '+${stats.revenueMoMPercent}% MoM',
                  subtextColor: Colors.green,
                ),
                right: StatCard(
                  label: 'Total Orders',
                  value: '${stats.totalOrders}',
                  subtext: '${stats.ordersAwaitingAction} awaiting action',
                ),
              ),
              const SizedBox(height: 12),
              _StatRow(
                isNarrow: isNarrow,
                left: StatCard(
                  label: 'Products',
                  value: '${stats.totalProducts}',
                  subtext: '${stats.activeProducts} active',
                ),
                right: StatCard(
                  label: 'Avg Order Value',
                  value: 'Rs ${formatNepaliStyle(stats.avgOrderValue)}',
                  subtext: 'per checkout',
                ),
              ),
              const SizedBox(height: 20),
       
              ChartCard(
                title: 'Revenue trend',
                subtitle: 'Monthly net revenue · Rs',
                child: RevenueLineChart(
                  data: stats.revenueTrend,
                  visitCount: visitCount,
                ),
              ),
              const SizedBox(height: 16),
              // Same issue here — was inline BarChart(...) before.
              ChartCard(
                title: 'Monthly orders',
                subtitle: 'Orders placed per month',
                child: MonthlyOrdersBarChart(data: stats.monthlyOrders),
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

class _StatRow extends StatelessWidget {
  final bool isNarrow;
  final Widget left;
  final Widget right;

  const _StatRow({
    required this.isNarrow,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return Column(
        children: [left, const SizedBox(height: 12), right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String storeName;
  final VoidCallback onBuyerView;
  const _Header({required this.storeName, required this.onBuyerView});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELLER STUDIO',
                style: TextStyle(
                  fontSize: Responsive.font(context, 11, capSystemScale: true),
                  letterSpacing: 1.2,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  storeName,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppFonts.brand,
                    fontSize: Responsive.font(context, 26, capSystemScale: true),
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Iconsax.shop, size: 16, color: AppColors.gold),
          label: Text(
            'Buyer view',
            style: TextStyle(
              fontSize: Responsive.font(context, 13, capSystemScale: true),
            ),
          ),
        ),
      ],
    );
  }
}