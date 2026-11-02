import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/inventory.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_inventory_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/seller_filter_dropdown.dart';

/// Status dropdown. The second value is what the API expects in ?status=.
const _statusOptions = <(String, String)>[
  ('All statuses', 'all'),
  ('In stock', 'IN_STOCK'),
  ('Low stock', 'LOW_STOCK'),
  ('Out of stock', 'OUT_OF_STOCK'),
];

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  final _outletFilter = ValueNotifier<String?>('all');
  final _statusFilter = ValueNotifier<String?>('all');
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final f = ref.read(stockFilterProvider);
    _searchCtrl.text = f.search;
    _outletFilter.value = f.outletId ?? 'all';
    _statusFilter.value = f.status ?? 'all';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _outletFilter.dispose();
    _statusFilter.dispose();
    super.dispose();
  }

  void _setFilter(StockFilter Function(StockFilter f) change) {
    final notifier = ref.read(stockFilterProvider.notifier);
    notifier.state = change(notifier.state);
  }

  void _onSearchChanged(String value) {
    setState(() {}); // shows or hides the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _setFilter(
        (f) => (search: value.trim(), outletId: f.outletId, status: f.status),
      );
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    _setFilter((f) => (search: '', outletId: f.outletId, status: f.status));
    setState(() {});
  }

  void _clearAll() {
    _debounce?.cancel();
    _searchCtrl.clear();
    _outletFilter.value = 'all';
    _statusFilter.value = 'all';
    ref.read(stockFilterProvider.notifier).state = kNoStockFilter;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sellerStockProvider);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory'),
          actions: [
            IconButton(
              tooltip: 'Overview',
              icon: const Icon(Icons.insights_outlined),
              onPressed: () => context.push('/seller/inventory/overview'),
            ),
            IconButton(
              tooltip: 'Stock history',
              icon: const Icon(Icons.history),
              onPressed: () => context.push('/seller/inventory/movements'),
            ),
            const SizedBox(width: 4),
          ],
        ),
        bottomNavigationBar: SellerBottomBar(
          label: 'Stock in',
          saving: false,
          onPressed: () => context.push('/seller/inventory/stock-in'),
        ),
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
                      onPressed: () => ref.invalidate(sellerStockProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          data: (items) => _page(_listBody(items)),
        ),
      ),
    );
  }

  /// Search + filters + [body], all in one scrolling list.
  Widget _page(List<Widget> body) {
    final outlets = ref.watch(sellerOutletsProvider).value ?? const <Outlet>[];
    final outletOptions = <(String, String)>[
      ('All outlets', 'all'),
      for (final o in outlets) (o.name, o.id),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.refresh(sellerStockProvider.future),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search products or SKU',
              prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close, size: 18),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Outlet on the left, status on the right.
          Row(
            children: [
              Expanded(
                child: SellerFilterDropdown(
                  options: outletOptions,
                  notifier: _outletFilter,
                  onChanged: (v) {
                    _outletFilter.value = v ?? 'all';
                    _setFilter(
                      (f) => (
                        search: f.search,
                        outletId: (v == null || v == 'all') ? null : v,
                        status: f.status,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SellerFilterDropdown(
                  options: _statusOptions,
                  notifier: _statusFilter,
                  onChanged: (v) {
                    _statusFilter.value = v ?? 'all';
                    _setFilter(
                      (f) => (
                        search: f.search,
                        outletId: f.outletId,
                        status: (v == null || v == 'all') ? null : v,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...body,
        ],
      ),
    );
  }

  List<Widget> _listBody(List<StockItem> items) {
    final filter = ref.watch(stockFilterProvider);
    final outletId = filter.outletId;
    final units = items.fold<int>(0, (sum, s) => sum + s.quantityAt(outletId));
    final active = filter != kNoStockFilter;

    return [
      _CountRow(
        text:
            '${items.length} item${items.length == 1 ? '' : 's'}'
            ' · $units unit${units == 1 ? '' : 's'}',
        showClear: active,
        onClear: _clearAll,
      ),
      const SizedBox(height: 8),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              active
                  ? 'Nothing matches your filters'
                  : 'No products yet.\nAdd products first, then stock them in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        )
      else
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SellerReveal(
              index: i < 6 ? i : 6,
              child: _StockCard(
                item: items[i],
                outletId: outletId,
                onTap: () => context.push(
                  '/seller/inventory/batches',
                  extra: items[i],
                ),
              ),
            ),
          ),
    ];
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.text,
    required this.showClear,
    required this.onClear,
  });

  final String text;
  final bool showClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (showClear)
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Clear filters',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.item,
    required this.outletId,
    required this.onTap,
  });

  final StockItem item;
  final String? outletId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final qty = item.quantityAt(outletId);

    // The status comes from the quantity, not from the server's status text.
    final String label;
    final bool positive;
    if (qty <= 0) {
      label = 'Out of stock';
      positive = false;
    } else if (item.status.toUpperCase().contains('LOW')) {
      label = 'Low stock';
      positive = false;
    } else {
      label = 'In stock';
      positive = true;
    }

    final cost = outletId == null
        ? item.totalCost
        : item.outlets
              .where((o) => o.outletId == outletId)
              .fold<double>(0, (sum, o) => sum + o.totalCost);

    final breakdown = outletId == null && item.outlets.isNotEmpty
        ? item.outlets.map((o) => '${o.outletName}: ${o.quantity}').join(' · ')
        : null;

    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.06),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.r2xl),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.sku != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'SKU ${item.sku}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SellerStatusPill(text: label, positive: positive),
                    if (breakdown != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        breakdown,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (cost > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Stock value ${formatPrice(cost)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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
                    '$qty',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    qty == 1 ? 'unit' : 'units',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}