import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/core/utils/seller_range_calender.dart';
import 'package:yanzee_app/data/models/inventory.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_inventory_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/seller_filter_chips.dart';

/// Type chips. The second value is what the API expects in ?type=.
const _typeOptions = <(String, String?)>[
  ('All', null),
  ('Stock in', 'STOCK_IN'),
  ('Stock out', 'STOCK_OUT'),
  ('Restored', 'STOCK_RESTORE'),
  ('Transfer in', 'TRANSFER_IN'),
  ('Transfer out', 'TRANSFER_OUT'),
  ('Write-off', 'WRITE_OFF'),
  ('Adjustment', 'ADJUSTMENT'),
];

/// Types that add stock (green) and types that take stock away (red).
/// Anything else, like ADJUSTMENT, is shown without a sign.
const _stockAddingTypes = {'STOCK_IN', 'STOCK_RESTORE', 'TRANSFER_IN'};
const _stockRemovingTypes = {'STOCK_OUT', 'TRANSFER_OUT', 'WRITE_OFF'};

/// API value -> label, built from the chips so both always match.
final _typeLabels = {
  for (final (label, value) in _typeOptions)
    if (value != null) value: label,
};

class StockMovementsScreen extends ConsumerStatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  ConsumerState<StockMovementsScreen> createState() =>
      _StockMovementsScreenState();
}

class _StockMovementsScreenState extends ConsumerState<StockMovementsScreen> {
  static final _short = DateFormat('dd MMM yyyy');

  void _setFilter(MovementFilter Function(MovementFilter f) change) {
    final notifier = ref.read(movementFilterProvider.notifier);
    notifier.state = change(notifier.state);
  }

  Future<void> _pickRange() async {
    final current = ref.read(movementFilterProvider).range;
    final result = await showRangeCalendarSheet(context, initial: current);
    if (result == null || !mounted) return;
    _setFilter(
      (f) => (range: result.cleared ? null : result.range, type: f.type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stockMovementsProvider);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Stock history')),
        body: async.when(
          skipLoadingOnReload: true,
          loading: () => _page(const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          ]),
          error: (e, _) => _page([
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(stockMovementsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          data: (movements) => _page(_listBody(movements)),
        ),
      ),
    );
  }

  /// Date range + type chips + [body], all in one scrolling list.
  Widget _page(List<Widget> body) {
    final filter = ref.watch(movementFilterProvider);
    final range = filter.range;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(stockMovementsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    range == null
                        ? 'All dates'
                        : '${_short.format(range.start)} - ${_short.format(range.end)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (range != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      _setFilter((f) => (range: null, type: f.type)),
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SellerFilterChips(
            options: _typeOptions,
            selected: filter.type,
            onSelected: (v) => _setFilter((f) => (range: f.range, type: v)),
          ),
          const SizedBox(height: 16),
          ...body,
        ],
      ),
    );
  }

  List<Widget> _listBody(List<StockMovement> movements) {
    final active = ref.watch(movementFilterProvider) != kNoMovementFilter;

    // Names for movement lines that arrive without a product name.
    final outlets = ref.watch(sellerOutletsProvider).value ?? const <Outlet>[];
    final outletNames = {for (final o in outlets) o.id: o.name};
    final stock = ref.watch(allStockItemsProvider).value ?? const <StockItem>[];
    final itemNames = {
      for (final s in stock) '${s.productId}|${s.variantId ?? ''}': s.name,
    };

    if (movements.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              active
                  ? 'No stock movements match your filters.'
                  : 'No stock movements yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return [
      for (var i = 0; i < movements.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SellerReveal(
            index: i < 6 ? i : 6,
            child: _MovementCard(
              movement: movements[i],
              outletName: outletNames[movements[i].outletId],
              itemNames: itemNames,
            ),
          ),
        ),
    ];
  }
}

class _MovementCard extends StatefulWidget {
  const _MovementCard({
    required this.movement,
    required this.outletName,
    required this.itemNames,
  });

  final StockMovement movement;
  final String? outletName;
  final Map<String, String> itemNames;

  @override
  State<_MovementCard> createState() => _MovementCardState();
}

class _MovementCardState extends State<_MovementCard> {
  static const _previewCount = 3;
  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static final _expiryFmt = DateFormat('dd MMM yyyy');

  bool _showAll = false;

  /// STOCK_RESTORE -> Restored (a type not in the list becomes "Some type").
  String _typeLabel(String type) {
    final known = _typeLabels[type.toUpperCase()];
    if (known != null) return known;

    final words = type
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w.toLowerCase())
        .toList();
    if (words.isEmpty) return 'Stock movement';
    return '${words.first[0].toUpperCase()}${words.first.substring(1)}'
        '${words.length > 1 ? ' ${words.skip(1).join(' ')}' : ''}';
  }

  /// Order sales are saved with the order number (#1014) as the reference.
  String _title(StockMovement m, String typeLabel) {
    final ref = m.referenceNumber;
    if (ref == null) return typeLabel;
    return ref.startsWith('#') ? 'Order $ref' : ref;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = widget.movement;

    final type = m.type.toUpperCase();
    final typeLabel = _typeLabel(m.type);
    final adds = _stockAddingTypes.contains(type);
    final removes = _stockRemovingTypes.contains(type);

    final outlet = m.outletName ?? widget.outletName;
    final created =
        m.createdAt == null ? null : _dateFmt.format(m.createdAt!.toLocal());

    final meta = [
      if (m.supplierName != null) m.supplierName!,
      if (m.performedBy != null) 'by ${m.performedBy}',
    ].join(' · ');

    final items = m.items;
    final visible = _showAll ? items : items.take(_previewCount).toList();
    final hidden = items.length - visible.length;

    final totals = [
      '${m.totalProducts} product${m.totalProducts == 1 ? '' : 's'}',
      '${m.totalQuantity} unit${m.totalQuantity == 1 ? '' : 's'}',
      if (m.totalCost > 0) formatPrice(m.totalCost),
    ].join(' · ');

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
                    _title(m, typeLabel),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                SellerStatusPill(text: typeLabel, positive: adds),
              ],
            ),
            if (outlet != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Iconsax.location, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      outlet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                meta,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              for (var i = 0; i < visible.length; i++)
                _ItemRow(
                  item: visible[i],
                  fallbackName: widget.itemNames[
                      '${visible[i].productId}|${visible[i].variantId ?? ''}'],
                  adds: adds,
                  removes: removes,
                  last: i == visible.length - 1 && hidden <= 0,
                  expiryFmt: _expiryFmt,
                ),
              if (hidden > 0 || _showAll && items.length > _previewCount)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(
                      _showAll ? 'Show fewer' : 'Show $hidden more',
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 6),
            Text(
              totals,
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

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.fallbackName,
    required this.adds,
    required this.removes,
    required this.last,
    required this.expiryFmt,
  });

  final MovementItem item;
  final String? fallbackName;
  final bool adds;
  final bool removes;
  final bool last;
  final DateFormat expiryFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final sign = adds ? '+' : (removes ? '-' : '');
    final qtyColor = adds
        ? const Color(0xFF1B7F3A)
        : (removes ? Colors.red.shade700 : scheme.onSurface);

    final details = [
      if (item.sku != null) 'SKU ${item.sku}',
      if (item.batchLabel != null) 'Batch ${item.batchLabel}',
      if (item.expiryDate != null) 'Exp ${expiryFmt.format(item.expiryDate!)}',
    ].join(' · ');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name ?? fallbackName ?? 'Product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${item.quantity}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: qtyColor,
                    ),
                  ),
                  if (item.unitCost > 0)
                    Text(
                      '@ ${formatPrice(item.unitCost)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!last)
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}