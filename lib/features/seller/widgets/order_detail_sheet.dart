import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_orders_provider.dart';

(Color bg, Color fg) _statusStyle(String status) {
  switch (status) {
    case 'Delivered':
      return (Colors.green.withOpacity(0.12), Colors.green.shade700);
    case 'On its way':
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

Future<void> showOrderDetailSheet(BuildContext context, WidgetRef ref, SellerOrder order) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderDetailSheet(orderId: order.id),
  );
}

class _OrderDetailSheet extends ConsumerWidget {
  final String orderId;
  const _OrderDetailSheet({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(sellerOrdersProvider);
    final notifier = ref.read(sellerOrdersProvider.notifier);
    final dateFmt = DateFormat('dd MMM yyyy');

    return ordersAsync.when(
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 200, child: Center(child: Text('Failed to load: $e'))),
      data: (orders) {
        // Re-look-up by id each rebuild so the sheet reflects live status changes.
        final order = orders.firstWhere((o) => o.id == orderId, orElse: () => orders.first);
        final (bg, fg) = _statusStyle(order.status);

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                      child: Text(order.status,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: order.productImageUrl.isNotEmpty
                          ? Image.network(order.productImageUrl, width: 72, height: 72, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _ph())
                          : _ph(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.productName.isNotEmpty ? order.productName : 'Item',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Qty ${order.itemCount}', style: const TextStyle(color: AppColors.textGray, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Text('\$${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 24),
                _infoRow(Icons.person_outline, 'Customer', order.customerName),
                _infoRow(Icons.calendar_today_outlined, 'Order date', dateFmt.format(order.date)),
                _infoRow(Icons.payments_outlined, 'Payment', order.paymentMethod),
                const SizedBox(height: 24),
                _buildActions(context, notifier, order),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ph() => Container(
        width: 72, height: 72, color: Colors.grey.shade100,
        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textGray),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textGray),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 13)),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          ],
        ),
      );

  Widget _buildActions(BuildContext context, dynamic notifier, SellerOrder order) {
    void act(String newStatus) {
      notifier.updateStatus(order.id, newStatus);
      Navigator.of(context).pop();
    }

    switch (order.status) {
      case 'New':
        return Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => act('Declined'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Decline', style: TextStyle(color: Colors.red)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => act('Processing'),
              child: const Text('Accept order', style: TextStyle(color: Colors.white)),
            ),
          ),
        ]);
      case 'Processing':
        return _fullBtn('Mark ready', () => act('Ready'));
      case 'Ready':
        return _fullBtn('Dispatch', () => act('On its way'));
      case 'On its way':
        return _fullBtn('Mark delivered', () => act('Delivered'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _fullBtn(String label, VoidCallback onPressed) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      );
}