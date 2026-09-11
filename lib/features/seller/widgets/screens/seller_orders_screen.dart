// features/seller/screens/seller_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_orders_provider.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  String _filter = 'All';
  final _tabs = ['All', 'New', 'Processing', 'Ready', 'On its way'];

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered': return Colors.green;
      case 'On its way': return Colors.blue;
      case 'Ready': return Colors.teal;
      case 'Processing': return Colors.orange;
      case 'Declined': return Colors.red;
      default: return Colors.amber.shade800; // New
    }
  }

  Widget? _actionButtons(SellerOrder order) {
    final notifier = ref.read(sellerOrdersProvider.notifier);
    switch (order.status) {
      case 'New':
        return Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => notifier.updateStatus(order.id, 'Declined'),
              child: const Text('Decline', style: TextStyle(color: Colors.red)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () => notifier.updateStatus(order.id, 'Processing'),
              child: const Text('Accept order', style: TextStyle(color: Colors.white)),
            ),
          ),
        ]);
      case 'Processing':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => notifier.updateStatus(order.id, 'Ready'),
            child: const Text('Mark ready', style: TextStyle(color: Colors.white)),
          ),
        );
      case 'Ready':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => notifier.updateStatus(order.id, 'On its way'),
            child: const Text('Dispatch', style: TextStyle(color: Colors.white)),
          ),
        );
      case 'On its way':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => notifier.updateStatus(order.id, 'Delivered'),
            child: const Text('Mark delivered', style: TextStyle(color: Colors.white)),
          ),
        );
      default:
        return null; // Delivered / Declined: no more actions
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F2),
        elevation: 0,
        title: const Text('Orders',
            style: TextStyle(fontFamily: AppFonts.brand, fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load orders: $e')),
        data: (orders) {
          final filtered = _filter == 'All' ? orders : orders.where((o) => o.status == _filter).toList();
          return Column(
            children: [
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final tab = _tabs[i];
                    final selected = tab == _filter;
                    return ChoiceChip(
                      label: Text(tab),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = tab),
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                      backgroundColor: Colors.white,
                      shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final o = filtered[i];
                    final action = _actionButtons(o);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(o.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor(o.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(o.status,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(o.status))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${o.customerName} · ${o.itemCount} item${o.itemCount > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                          const SizedBox(height: 4),
                          Text('\$${o.total.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          if (action != null) ...[const SizedBox(height: 10), action],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}