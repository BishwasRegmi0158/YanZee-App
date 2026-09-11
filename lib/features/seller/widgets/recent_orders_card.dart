// features/seller/widgets/recent_orders_card.dart
import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/features/seller/widgets/order_status_badge.dart';

class RecentOrdersCard extends StatelessWidget {
  final List<SellerOrder> orders;
  final int totalCount; // pass the full order count, orders can be just the preview slice

  const RecentOrdersCard({super.key, required this.orders, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent orders',
                  style: TextStyle(
                      fontFamily: AppFonts.brand, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
              Text('$totalCount total',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No orders yet', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
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
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: order.productImageUrl.isNotEmpty
                          ? Image.network(
                              order.productImageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                color: Colors.grey.shade200,
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.textGray),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.productName.isNotEmpty ? order.productName : 'Order #${order.id}',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text('${order.customerName} · ${dateFmt.format(order.date)}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textGray)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${order.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.ink)),
                        const SizedBox(height: 4),
                        OrderStatusBadge(status: order.status),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}