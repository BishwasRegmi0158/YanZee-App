import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/store_order.dart';
import 'package:yanzee_app/data/services/store_order_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_inventory_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/store_orders_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/store_order_widgets.dart';

/// What the seller chose in the status sheet.
typedef StatusChange = ({
  String status,
  String? reason,
  bool markAsPaid,
  bool restoreStock,
});

String _err(Object e) => e.toString().replaceFirst('Exception: ', '');

bool _isFinal(String status) =>
    status == StoreOrderStatus.cancelled || status == StoreOrderStatus.returned;

/// A message when the change would skip a step or is not possible, or null
/// when the server should decide. Orders go step by step:
/// Pending, Processing, Delivered.
String? _skipMessage(String current, String target) {
  final c = current.toUpperCase();
  final t = target.toUpperCase();
  if (c == t) {
    return 'This order is already ${prettyEnum(c).toLowerCase()}.';
  }
  if (_isFinal(c)) {
    return 'A ${prettyEnum(c).toLowerCase()} order can not be changed any more.';
  }
  if (c == StoreOrderStatus.pending && t == StoreOrderStatus.delivered) {
    return 'Orders go step by step. Move this order to Processing first, then mark it as Delivered.';
  }
  if (t == StoreOrderStatus.returned && c != StoreOrderStatus.delivered) {
    return 'Only a delivered order can be returned.';
  }
  if (t == StoreOrderStatus.processing && c != StoreOrderStatus.pending) {
    return 'Only a pending order can be moved to Processing.';
  }
  return null;
}

class StoreOrderDetailScreen extends ConsumerStatefulWidget {
  const StoreOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<StoreOrderDetailScreen> createState() =>
      _StoreOrderDetailScreenState();
}

class _StoreOrderDetailScreenState
    extends ConsumerState<StoreOrderDetailScreen> {
  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  bool _busy = false;

  Future<void> _alert(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(StoreOrderDetail order) async {
    final change = await showModalBottomSheet<StatusChange>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellerFormTheme(child: _StatusSheet(current: order.status)),
    );
    if (change == null || !mounted) return;

    // A skipped step shows an alert.
    final blocked = _skipMessage(order.status, change.status);
    if (blocked != null) {
      await _alert("Can't change the status", blocked);
      return;
    }

    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null) {
      AppToast.error(context, 'No store loaded.');
      return;
    }

    setState(() => _busy = true);
    try {
      final message = await ref.read(storeOrderApiServiceProvider).updateStatus(
            storeId,
            order.id,
            status: change.status,
            reason: change.reason,
            markAsPaid: change.markAsPaid,
            restoreStock: change.status == StoreOrderStatus.returned
                ? change.restoreStock
                : null,
          );
      ref.invalidate(storeOrderDetailProvider(order.id));
      ref.invalidate(storeOrdersProvider);
      // Cancelling or returning an order can put stock back.
      ref.invalidate(sellerStockProvider);
      ref.invalidate(allStockItemsProvider);
      if (!mounted) return;
      AppToast.success(context, message);
    } catch (e) {
      if (!mounted) return;
      // The server also refuses a skipped step; its message is shown here.
      await _alert('Status not changed', _err(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(storeOrderDetailProvider(widget.orderId));
    final order = async.value;

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(
          title: Text(order == null ? 'Order' : 'Order #${order.orderNumber}'),
        ),
        bottomNavigationBar: (order != null && !_isFinal(order.status))
            ? SellerBottomBar(
                label: 'Update status',
                saving: _busy,
                onPressed: () => _changeStatus(order),
              )
            : null,
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_err(e), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(
                      storeOrderDetailProvider(widget.orderId),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (o) => o == null
              ? const Center(child: Text('No store loaded.'))
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(
                    storeOrderDetailProvider(widget.orderId).future,
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      SellerReveal(index: 0, child: _headerCard(o)),
                      const SizedBox(height: 16),
                      SellerReveal(index: 1, child: _itemsCard(o)),
                      const SizedBox(height: 16),
                      SellerReveal(index: 2, child: _paymentCard(o)),
                      const SizedBox(height: 16),
                      SellerReveal(index: 3, child: _customerCard(o)),
                      if (o.activities.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SellerReveal(index: 4, child: _activityCard(o)),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ cards

  String? _date(DateTime? d) =>
      d == null ? null : _dateFmt.format(d.toLocal());

  Widget _headerCard(StoreOrderDetail o) {
    return SellerSectionCard(
      icon: Icons.receipt_long_outlined,
      title: 'Order #${o.orderNumber}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StoreOrderStatusPill(o.status),
              StorePaymentPill(o.paymentStatus),
              StoreChannelPill(o.channel),
            ],
          ),
          const SizedBox(height: 12),
          SellerInfoRow(label: 'Placed at', value: o.outletName),
          SellerInfoRow(label: 'Created by', value: o.createdBy),
          SellerInfoRow(label: 'Payment', value: prettyEnum(o.paymentMethod)),
          SellerInfoRow(label: 'Created', value: _date(o.createdAt)),
          SellerInfoRow(label: 'Updated', value: _date(o.updatedAt), last: true),
        ],
      ),
    );
  }

  Widget _itemsCard(StoreOrderDetail o) {
    final items = o.summary.items;
    return SellerSectionCard(
      icon: Icons.inventory_2_outlined,
      title: 'Items (${o.summary.totalQuantity})',
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _LineTile(line: items[i], last: i == items.length - 1),
        ],
      ),
    );
  }

  Widget _paymentCard(StoreOrderDetail o) {
    final t = o.summary;
    final due = math.max(0.0, t.total - t.paidAmount);
    final colors = context.colors;

    final discountLabel = t.orderDiscountType == 'PERCENT'
        ? 'Order discount (${t.orderDiscountValue.toStringAsFixed(0)}%)'
        : 'Order discount';

    return SellerSectionCard(
      icon: Icons.payments_outlined,
      title: 'Payment summary',
      child: Column(
        children: [
          _MoneyRow('Subtotal', formatPrice(t.subtotal)),
          if (t.itemDiscount > 0)
            _MoneyRow('Item discounts', '- ${formatPrice(t.itemDiscount)}'),
          if (t.orderDiscountAmount > 0)
            _MoneyRow(
              discountLabel,
              '- ${formatPrice(t.orderDiscountAmount)}',
            ),
          _MoneyRow('Delivery fee', formatPrice(t.deliveryFee)),
          const Divider(height: 20),
          _MoneyRow('Total', formatPrice(t.total), bold: true),
          _MoneyRow('Paid', formatPrice(t.paidAmount)),
          if (t.refundedAmount > 0)
            _MoneyRow('Refunded', formatPrice(t.refundedAmount)),
          if (due > 0 && o.status != StoreOrderStatus.cancelled)
            _MoneyRow(
              'Balance due',
              formatPrice(due),
              color: colors.error,
              bold: true,
            ),
        ],
      ),
    );
  }

  Widget _customerCard(StoreOrderDetail o) {
    final c = o.customer;
    return SellerSectionCard(
      icon: Icons.person_outline,
      title: 'Customer',
      child: Column(
        children: [
          SellerInfoRow(label: 'Name', value: c.name),
          SellerInfoRow(label: 'Phone', value: c.phone),
          SellerInfoRow(label: 'Email', value: c.email),
          SellerInfoRow(label: 'Address', value: c.fullAddress),
          SellerInfoRow(label: 'Order note', value: c.orderNote),
          SellerInfoRow(label: 'Customer note', value: c.customerNote),
          SellerInfoRow(
            label: 'Orders',
            value: c.totalOrders == 0 ? null : '${c.totalOrders}',
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _activityCard(StoreOrderDetail o) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SellerSectionCard(
      icon: Icons.history,
      title: 'Activity',
      child: Column(
        children: [
          for (final a in o.activities)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (a.actorName != null)
                              a.actorRole == null
                                  ? a.actorName!
                                  : '${a.actorName} (${a.actorRole})',
                            if (a.createdAt != null) _date(a.createdAt)!,
                          ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- pieces

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.value, {this.bold = false, this.color});

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line, required this.last});

  final StoreOrderLine line;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String? discount;
    if (line.discountAmount > 0) {
      discount = line.discountType == 'PERCENT'
          ? '${line.discountValue.toStringAsFixed(0)}% off'
          : '${formatPrice(line.discountAmount)} off';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SellerDetailAvatar(
                url: line.image,
                icon: Icons.inventory_2_outlined,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${line.quantity} × ${formatPrice(line.unitPrice)}'
                      '${discount == null ? '' : ' · $discount'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (line.sku != null)
                      Text(
                        'SKU ${line.sku}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
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
                    formatPrice(line.lineTotal),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (line.discountAmount > 0)
                    Text(
                      formatPrice(line.totalPrice),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: scheme.outlineVariant),
      ],
    );
  }
}

// ------------------------------------------------------------ status sheet

class _StatusSheet extends StatefulWidget {
  const _StatusSheet({required this.current});

  final String current;

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  static const _options = <(String, String, String)>[
    (StoreOrderStatus.processing, 'Processing', 'Start preparing this order'),
    (
      StoreOrderStatus.delivered,
      'Delivered',
      'The customer has received the order',
    ),
    (StoreOrderStatus.cancelled, 'Cancelled', 'Cancel this order'),
    (
      StoreOrderStatus.returned,
      'Returned',
      'The customer sent the items back',
    ),
  ];

  late String? _selected = switch (widget.current) {
    StoreOrderStatus.pending => StoreOrderStatus.processing,
    StoreOrderStatus.processing => StoreOrderStatus.delivered,
    _ => null,
  };
  bool _markPaid = false;
  bool _restock = true;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _needsReason =>
      _selected == StoreOrderStatus.cancelled ||
      _selected == StoreOrderStatus.returned;

  bool get _valid =>
      _selected != null && (!_needsReason || _reason.text.trim().isNotEmpty);

  Widget _option(String status, String title, String hint) {
    final colors = context.colors;
    final selected = _selected == status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.rXl),
        onTap: () => setState(() => _selected = status),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? colors.secondaryContainer
                : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.rXl),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.r2xl),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Update status',
                        style: context.text.headlineSmall,
                      ),
                    ),
                    StoreOrderStatusPill(widget.current),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Orders go step by step: Pending, Processing, Delivered.',
                  style: context.text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final (status, title, hint) in _options)
                  _option(status, title, hint),
                if (_selected == StoreOrderStatus.delivered)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _markPaid,
                    onChanged: (v) => setState(() => _markPaid = v ?? false),
                    title: const Text('Also mark the order as paid'),
                  ),
                if (_needsReason) ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: _reason,
                    minLines: 2,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _selected == StoreOrderStatus.returned
                          ? 'Reason for the return'
                          : 'Reason for cancelling',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
                if (_selected == StoreOrderStatus.returned)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _restock,
                    onChanged: (v) => setState(() => _restock = v),
                    title: const Text('Put the items back in stock'),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _valid
                        ? () => Navigator.of(context).pop<StatusChange>((
                            status: _selected!,
                            reason: _needsReason ? _reason.text.trim() : null,
                            markAsPaid:
                                _selected == StoreOrderStatus.delivered &&
                                _markPaid,
                            restoreStock:
                                _selected == StoreOrderStatus.returned &&
                                _restock,
                          ))
                        : null,
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}