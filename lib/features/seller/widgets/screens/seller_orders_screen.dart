// features/seller/screens/seller_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_orders_provider.dart';
import 'package:yanzee_app/features/seller/widgets/order_detail_sheet.dart';

enum _SortOption { newest, oldest, highestValue, lowestValue }

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  String _filter = 'All';
  _SortOption _sort = _SortOption.newest;
  final _tabs = ['All', 'New', 'Processing', 'Ready', 'On its way'];
  final _dateFmt = DateFormat('dd MMM yyyy');

  (Color bg, Color fg) _statusStyle(String status) {
    switch (status) {
      case 'Delivered':
        return (Colors.green.withOpacity(0.12), Colors.green.shade700);
      case 'On its way':
        return (const Color(0xFFDCEBFB), const Color(0xFF2563EB));
      case 'Processing':
        return (const Color(0xFFDCEBFB), const Color(0xFF2563EB));
      case 'Ready':
        return (const Color(0xFFF3E8D3), const Color(0xFF8A6D3B));
      case 'Declined':
        return (Colors.red.withOpacity(0.1), Colors.red.shade700);
      default: // New
        return (const Color(0xFFFBE3D0), const Color(0xFFC2540C));
    }
  }

  List<SellerOrder> _applySort(List<SellerOrder> orders) {
    final sorted = [...orders];
    switch (_sort) {
      case _SortOption.newest:
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SortOption.oldest:
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SortOption.highestValue:
        sorted.sort((a, b) => b.total.compareTo(a.total));
        break;
      case _SortOption.lowestValue:
        sorted.sort((a, b) => a.total.compareTo(b.total));
        break;
    }
    return sorted;
  }

  String _sortLabel(_SortOption option) {
    switch (option) {
      case _SortOption.newest:
        return 'Newest first';
      case _SortOption.oldest:
        return 'Oldest first';
      case _SortOption.highestValue:
        return 'Highest value';
      case _SortOption.lowestValue:
        return 'Lowest value';
    }
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text('Sort orders by', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              ..._SortOption.values.map(
                (option) => RadioListTile<_SortOption>(
                  value: option,
                  groupValue: _sort,
                  activeColor: Colors.black,
                  title: Text(_sortLabel(option)),
                  onChanged: (v) {
                    setState(() => _sort = v!);
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _actionButtons(SellerOrder order) {
    final notifier = ref.read(sellerOrdersProvider.notifier);
    switch (order.status) {
      case 'New':
        return Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => notifier.updateStatus(order.id, 'Declined'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Decline', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => notifier.updateStatus(order.id, 'Processing'),
              child: const Text('Accept order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ]);
      case 'Processing':
        return _fullWidthButton('Mark ready', () => notifier.updateStatus(order.id, 'Ready'));
      case 'Ready':
        return _fullWidthButton('Dispatch', () => notifier.updateStatus(order.id, 'On its way'));
      case 'On its way':
        return _fullWidthButton('Mark delivered', () => notifier.updateStatus(order.id, 'Delivered'));
      default:
        return null; // Delivered / Declined: no more actions
    }
  }

  Widget _fullWidthButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      body: SafeArea(
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, _) => Center(child: Text('Failed to load orders: $e')),
          data: (orders) {
            final byFilter = _filter == 'All' ? orders : orders.where((o) => o.status == _filter).toList();
            final filtered = _applySort(byFilter);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Orders',
                              style: TextStyle(
                                  fontFamily: AppFonts.brand,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink)),
                          SizedBox(height: 2),
                          Text('Manage and fulfil customer requests',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textGray)),
                        ],
                      ),
                      GestureDetector(
                        onTap: _openMenu,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                          child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            orders.isEmpty ? 'No orders yet' : 'No $_filter orders',
                            style: const TextStyle(color: AppColors.textGray),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final o = filtered[i];
                            final action = _actionButtons(o);
                            final (bg, fg) = _statusStyle(o.status);
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => showOrderDetailSheet(context, ref, o),
                                    behavior: HitTestBehavior.opaque,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Order #${o.id}',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                                              child: Text(o.status,
                                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: o.productImageUrl.isNotEmpty
                                                  ? Image.network(
                                                      o.productImageUrl,
                                                      width: 52,
                                                      height: 52,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => _placeholder(),
                                                    )
                                                  : _placeholder(),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    o.productName.isNotEmpty ? o.productName : 'Order #${o.id}',
                                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text('Qty ${o.itemCount} · ${o.customerName}',
                                                      style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                                                  const SizedBox(height: 2),
                                                  Text('${_dateFmt.format(o.date)} · ${o.paymentMethod}',
                                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textGray)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('\$${o.total.toStringAsFixed(0)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (action != null) ...[const SizedBox(height: 14), action],
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
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        color: Colors.grey.shade100,
        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textGray, size: 18),
      );
}