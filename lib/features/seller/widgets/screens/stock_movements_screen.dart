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

/// Types that add stock. They get the green pill; the others get the grey one.
const _stockAddingTypes = {'STOCK_IN', 'STOCK_RESTORE', 'TRANSFER_IN'};

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
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: current,
    );
    if (picked == null || !mounted) return;

    final range = DateTimeRange(
      start: DateTime(picked.start.year, picked.start.month, picked.start.day),
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
    _setFilter((f) => (range: range, type: f.type));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stockMovementsProvider);
    final outlets = ref.watch(sellerOutletsProvider).value ?? const <Outlet>[];
    final outletNames = {for (final o in outlets) o.id: o.name};

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
          data: (movements) => _page(_listBody(movements, outletNames)),
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
                  icon: const Icon(Icons.date_range, size: 18),
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

  List<Widget> _listBody(
    List<StockMovement> movements,
    Map<String, String> outletNames,
  ) {
    final active = ref.watch(movementFilterProvider) != kNoMovementFilter;

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
            ),
          ),
        ),
    ];
  }
}

class _MovementCard extends StatelessWidget {
  const _MovementCard({required this.movement, required this.outletName});

  final StockMovement movement;
  final String? outletName;

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = movement;
    final typeLabel = _typeLabel(m.type);
    final created =
        m.createdAt == null ? null : _dateFmt.format(m.createdAt!.toLocal());
    final isIn = _stockAddingTypes.contains(m.type.toUpperCase());

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