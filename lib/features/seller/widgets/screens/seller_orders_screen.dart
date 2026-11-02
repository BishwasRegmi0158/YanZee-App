// features/seller/widgets/screens/seller_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/order_detail_sheet.dart';
import 'package:yanzee_app/features/seller/widgets/order_status_badge.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_orders_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_filter_chips.dart';

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
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text('Sort orders by', style: ctx.text.headlineSmall),
              ),
              ..._SortOption.values.map(
                (option) => RadioListTile<_SortOption>(
                  value: option,
                  groupValue: _sort,
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
    final colors = context.colors;

    switch (order.status) {
      case 'New':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.updateStatus(order.id, 'Declined'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withValues(alpha: 0.4)),
                ),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () => notifier.updateStatus(order.id, 'Processing'),
                child: const Text('Accept order'),
              ),
            ),
          ],
        );
      case 'Processing':
        return _fullWidthButton(
          'Mark ready',
          () => notifier.updateStatus(order.id, 'Ready'),
        );
      case 'Ready':
        return _fullWidthButton(
          'Dispatch',
          () => notifier.updateStatus(order.id, 'On its way'),
        );
      case 'On its way':
        return _fullWidthButton(
          'Mark delivered',
          () => notifier.updateStatus(order.id, 'Delivered'),
        );
      default:
        return null; // Delivered / Declined: no more actions
    }
  }

  Widget _fullWidthButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      body: SafeArea(
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load orders: $e')),
          data: (orders) {
            final byFilter = _filter == 'All'
                ? orders
                : orders.where((o) => o.status == _filter).toList();
            final filtered = _applySort(byFilter);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Orders', style: context.text.headlineLarge),
                          const SizedBox(height: 2),
                          Text(
                            'Manage and fulfil customer requests',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _openMenu,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_horiz,
                            color: colors.onPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SellerFilterChips(
                    options: [
                      for (final tab in _tabs)
                        (tab, tab == 'All' ? null : tab),
                    ],
                    selected: _filter == 'All' ? null : _filter,
                    onSelected: (v) => setState(() => _filter = v ?? 'All'),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            orders.isEmpty
                                ? 'No orders yet'
                                : 'No $_filter orders',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final o = filtered[i];
                            final action = _actionButtons(o);
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.r2xl,
                                ),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        showOrderDetailSheet(context, ref, o),
                                    behavior: HitTestBehavior.opaque,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Order #${o.id}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            OrderStatusBadge(status: o.status),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.rLg,
                                                  ),
                                              child: o.productImageUrl
                                                      .isNotEmpty
                                                  ? Image.network(
                                                      o.productImageUrl,
                                                      width: 52,
                                                      height: 52,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) =>
                                                              _placeholder(
                                                                context,
                                                              ),
                                                    )
                                                  : _placeholder(context),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    o.productName.isNotEmpty
                                                        ? o.productName
                                                        : 'Order #${o.id}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'Qty ${o.itemCount} · ${o.customerName}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: colors
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${_dateFmt.format(o.date)} · ${o.paymentMethod}',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: colors
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              formatPrice(o.total.toDouble()),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (action != null) ...[
                                    const SizedBox(height: 14),
                                    action,
                                  ],
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

  Widget _placeholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 52,
      height: 52,
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colors.onSurfaceVariant,
        size: 18,
      ),
    );
  }
}