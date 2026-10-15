import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/inventory.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_inventory_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _query = '';
  String? _outletId; // null = all outlets

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sellerStockProvider);
    final outlets = ref.watch(sellerOutletsProvider).value ?? const <Outlet>[];

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory'),
          actions: [
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
          loading: () => const Center(child: CircularProgressIndicator()),
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
                    onPressed: () => ref.invalidate(sellerStockProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            final q = _query.trim().toLowerCase();
            final filtered = items.where((s) {
              if (_outletId != null && s.quantityAt(_outletId) <= 0) {
                return false;
              }
              if (q.isEmpty) return true;
              return s.name.toLowerCase().contains(q) ||
                  (s.sku ?? '').toLowerCase().contains(q);
            }).toList();
            final units = filtered.fold<int>(
              0,
              (sum, s) => sum + s.quantityAt(_outletId),
            );
            final theme = Theme.of(context);

            return RefreshIndicator(
              onRefresh: () => ref.refresh(sellerStockProvider.future),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search products or SKU',
                      prefixIcon: Icon(Iconsax.search_normal_1, size: 20),
                    ),
                  ),
                  if (outlets.length > 1) ...[
                    const SizedBox(height: 12),
                    _OutletChips(
                      outlets: outlets,
                      selectedId: _outletId,
                      onSelected: (id) => setState(() => _outletId = id),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '${filtered.length} item${filtered.length == 1 ? '' : 's'}'
                    ' · $units unit${units == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          items.isEmpty
                              ? 'No products yet.\nAdd products first, then stock them in.'
                              : 'Nothing matches your filters',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < filtered.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SellerReveal(
                          index: i < 6 ? i : 6,
                          child: _StockCard(
                            item: filtered[i],
                            outletId: _outletId,
                          ),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OutletChips extends StatelessWidget {
  const _OutletChips({
    required this.outlets,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Outlet> outlets;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  Widget _chip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? scheme.onPrimary : scheme.onSurface,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(context, 'All outlets', selectedId == null,
              () => onSelected(null)),
          for (final o in outlets)
            _chip(context, o.name, selectedId == o.id, () => onSelected(o.id)),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.item, required this.outletId});

  final StockItem item;
  final String? outletId;

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
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
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
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (item.sku != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'SKU ${item.sku}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
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
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  if (cost > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Stock value ${formatPrice(cost)}',
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
                  '$qty',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  qty == 1 ? 'unit' : 'units',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}