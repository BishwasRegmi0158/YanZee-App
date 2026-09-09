import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/data/models/orders_state.dart';

/// Reads live from OrdersState — nothing hardcoded. Shows an empty
/// state until a real order gets added via OrdersState.instance.addOrder(),
/// which should be called from wherever checkout completes.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    OrdersState.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    OrdersState.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final orders = OrdersState.instance.orders;

    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        title: const Text('My Orders', style: TextStyle(color: AuthColors.textDark)),
      ),
      body: SafeArea(
        child: orders.isEmpty
            ? _emptyState()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [for (final order in orders) _orderCard(order)],
              ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping_outlined, size: 48, color: AuthColors.iconMuted),
            const SizedBox(height: 12),
            const Text('No orders yet', style: TextStyle(fontWeight: FontWeight.w700, color: AuthColors.textDark)),
            const SizedBox(height: 6),
            const Text(
              'Orders you place will show up here.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9A9A9A)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(OrderSummary order) {
    final isDelivered = order.status == 'Delivered';
    final isTransit = order.status == 'In transit';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEBE7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AuthColors.textDark)),
                const SizedBox(height: 4),
                Text(
                  '${order.date} · ${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9A9A9A)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AuthColors.textDark)),
              const SizedBox(height: 4),
              Text(
                order.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDelivered
                      ? const Color(0xFF2E9E5B)
                      : (isTransit ? const Color(0xFFC98A2C) : const Color(0xFF6B6B6B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}