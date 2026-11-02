import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/core/theme/app_widgets.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_orders_provider.dart';

PillTone _statusTone(String status) {
  switch (status) {
    case 'Delivered':
      return PillTone.green;
    case 'On its way':
    case 'Processing':
      return PillTone.blue;
    case 'Ready':
      return PillTone.gray;
    case 'Declined':
      return PillTone.red;
    default: // New
      return PillTone.orange;
  }
}

Future<void> showOrderDetailSheet(
  BuildContext context,
  WidgetRef ref,
  SellerOrder order,
) {
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
    final colors = context.colors;
    final ordersAsync = ref.watch(sellerOrdersProvider);
    final notifier = ref.read(sellerOrdersProvider.notifier);
    final dateFmt = DateFormat('dd MMM yyyy');

    return ordersAsync.when(
      loading: () => const _SheetMessage(child: CircularProgressIndicator()),
      error: (e, _) => _SheetMessage(child: Text('Failed to load: $e')),
      data: (orders) {
        // Re-look-up by id each rebuild so the sheet reflects live status changes.
        final order = orders.firstWhere(
          (o) => o.id == orderId,
          orElse: () => orders.first,
        );

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.r2xl),
              ),
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: context.text.headlineSmall,
                    ),
                    StatusPill(
                      label: order.status,
                      tone: _statusTone(order.status),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.rXl),
                      child: order.productImageUrl.isNotEmpty
                          ? Image.network(
                              order.productImageUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(context),
                            )
                          : _placeholder(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.productName.isNotEmpty
                                ? order.productName
                                : 'Item',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty ${order.itemCount}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatPrice(order.total.toDouble()),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _infoRow(
                  context,
                  Icons.person_outline,
                  'Customer',
                  order.customerName,
                ),
                _infoRow(
                  context,
                  Icons.calendar_today_outlined,
                  'Order date',
                  dateFmt.format(order.date),
                ),
                _infoRow(
                  context,
                  Icons.payments_outlined,
                  'Payment',
                  order.paymentMethod,
                ),
                const SizedBox(height: 24),
                _buildActions(context, notifier, order),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 72,
      height: 72,
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    dynamic notifier,
    SellerOrder order,
  ) {
    final colors = context.colors;

    void act(String newStatus) {
      notifier.updateStatus(order.id, newStatus);
      Navigator.of(context).pop();
    }

    switch (order.status) {
      case 'New':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => act('Declined'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(
                    color: colors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () => act('Processing'),
                child: const Text('Accept order'),
              ),
            ),
          ],
        );
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
        child: FilledButton(onPressed: onPressed, child: Text(label)),
      );
}

/// Loading / error box shown in place of the sheet.
class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 200,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.r2xl),
        ),
      ),
      child: child,
    );
  }
}