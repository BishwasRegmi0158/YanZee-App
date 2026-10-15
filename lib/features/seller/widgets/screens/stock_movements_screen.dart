import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/inventory.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_inventory_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';

class StockMovementsScreen extends ConsumerStatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  ConsumerState<StockMovementsScreen> createState() =>
      _StockMovementsScreenState();
}

class _StockMovementsScreenState extends ConsumerState<StockMovementsScreen> {
  DateTimeRange? _range; // null = all dates

  static final _short = DateFormat('dd MMM yyyy');

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _range = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        // Whole last day included.
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stockMovementsProvider(_range));
    final outlets = ref.watch(sellerOutletsProvider).value ?? const <Outlet>[];
    final outletNames = {for (final o in outlets) o.id: o.name};

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Stock history')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _range == null
                            ? 'All dates'
                            : '${_short.format(_range!.start)} - ${_short.format(_range!.end)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (_range != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _range = null),
                      child: const Text('Clear'),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.toString().replaceFirst('Exception: ', ''),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(stockMovementsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (movements) => RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(stockMovementsProvider(_range).future),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (movements.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text(
                              _range == null
                                  ? 'No stock movements yet.'
                                  : 'No stock movements in this period.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        for (var i = 0; i < movements.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SellerReveal(
                              index: i < 6 ? i : 6,
                              child: _MovementCard(
                                movement: movements[i],
                                outletName: outletNames[movements[i].outletId],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  const _MovementCard({required this.movement, required this.outletName});

  final StockMovement movement;
  final String? outletName;

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  /// STOCK_IN -> Stock in
  String _typeLabel(String t) {
    final words = t
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w.toLowerCase())
        .toList();
    if (words.isEmpty) return 'Stock movement';
    return '${words.first[0].toUpperCase()}${words.first.substring(1)}'
        '${words.length > 1 ? ' ${words.skip(1).join(' ')}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = movement;
    final typeLabel = _typeLabel(m.type);
    final created =
        m.createdAt == null ? null : _dateFmt.format(m.createdAt!.toLocal());
    final isIn = m.type.toUpperCase().contains('IN');

    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.referenceNumber ?? typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                SellerStatusPill(text: typeLabel, positive: isIn),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (m.supplierName != null) m.supplierName!,
                if (outletName != null) outletName!,
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              '${m.totalProducts} product${m.totalProducts == 1 ? '' : 's'}'
              ' · ${m.totalQuantity} unit${m.totalQuantity == 1 ? '' : 's'}'
              ' · ${formatPrice(m.totalCost)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (m.note != null) ...[
              const SizedBox(height: 4),
              Text(
                m.note!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (created != null) ...[
              const SizedBox(height: 6),
              Text(
                created,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}