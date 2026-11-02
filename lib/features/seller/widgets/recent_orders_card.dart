// features/seller/widgets/recent_orders_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/order_status_badge.dart';

class RecentOrdersCard extends StatelessWidget {
  final List<SellerOrder> orders;
  final int totalCount; // the full order count; orders can be just the preview slice
  final void Function(SellerOrder order)? onOrderTap;

  const RecentOrdersCard({
    super.key,
    required this.orders,
    required this.totalCount,
    this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('dd MMM yyyy');

    Widget thumbPlaceholder({bool withIcon = false}) => Container(
          width: 44,
          height: 44,
          color: colors.surfaceContainerHighest,
          child: withIcon
              ? Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                )
              : null,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.r2xl),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent orders', style: context.text.headlineSmall),
              Text(
                '$totalCount total',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No orders yet',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final order = orders[index];
                return InkWell(
                  onTap: onOrderTap == null ? null : () => onOrderTap!(order),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.rLg),
                        child: order.productImageUrl.isNotEmpty
                            ? Image.network(
                                order.productImageUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    thumbPlaceholder(),
                              )
                            : thumbPlaceholder(withIcon: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.productName.isNotEmpty
                                  ? order.productName
                                  : 'Order #${order.id}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.customerName} · ${dateFmt.format(order.date)}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatPrice(order.total.toDouble()),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          OrderStatusBadge(status: order.status),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}