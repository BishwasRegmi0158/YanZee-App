import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/inventory_overview.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_inventory_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_filter_dropdown.dart';

class InventoryOverviewScreen extends ConsumerStatefulWidget {
  const InventoryOverviewScreen({super.key});

  @override
  ConsumerState<InventoryOverviewScreen> createState() =>
      _InventoryOverviewScreenState();
}

class _InventoryOverviewScreenState
    extends ConsumerState<InventoryOverviewScreen> {
  final _outletFilter = ValueNotifier<String?>('all');

  @override
  void initState() {
    super.initState();
    _outletFilter.value = ref.read(overviewOutletProvider) ?? 'all';
  }

  @override
  void dispose() {
    _outletFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inventoryOverviewProvider);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Inventory overview')),
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
                      onPressed: () =>
                          ref.invalidate(inventoryOverviewProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          data: (overview) => _page(
            overview == null
                ? const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: Text('No store loaded.')),
                    ),
                  ]
                : _body(overview),
          ),
        ),
      ),
    );
  }

  /// Outlet dropdown + [body], all in one scrolling list.
  Widget _page(List<Widget> body) {
    final outlets = ref.watch(sellerOutletsProvider).value ?? const <Outlet>[];
    final options = <(String, String)>[
      ('All active outlets', 'all'),
      for (final o in outlets) (o.name, o.id),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.refresh(inventoryOverviewProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SellerFilterDropdown(
            options: options,
            notifier: _outletFilter,
            onChanged: (v) {
              _outletFilter.value = v ?? 'all';
              ref.read(overviewOutletProvider.notifier).state =
                  (v == null || v == 'all') ? null : v;
            },
          ),
          const SizedBox(height: 16),
          ...body,
        ],
      ),
    );
  }

  List<Widget> _body(InventoryOverview o) {
    final status = context.status;
    final v = o.value;
    final h = o.health;
    final loss = v.potentialProfit < 0;

    return [
      SellerReveal(
        index: 0,
        child: SellerSectionCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Inventory value',
          child: _StatGrid([
            _Stat('Selling value', formatPrice(v.sellingValue)),
            _Stat('Cost value', formatPrice(v.costValue)),
            _Stat(
              'Potential profit',
              formatPrice(v.potentialProfit),
              color: loss ? status.dangerFg : status.successFg,
            ),
            _Stat('Products', '${v.totalProducts}'),
            _Stat('Units in stock', '${v.totalQuantity}'),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      SellerReveal(
        index: 1,
        child: SellerSectionCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Stock health',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HealthBar(
                inStock: h.inStock,
                lowStock: h.lowStock,
                outOfStock: h.outOfStock,
              ),
              const SizedBox(height: 14),
              _LegendRow(
                color: status.successFg,
                label: 'In stock',
                count: h.inStock,
              ),
              _LegendRow(
                color: status.warningFg,
                label: 'Low stock',
                count: h.lowStock,
              ),
              _LegendRow(
                color: status.dangerFg,
                label: 'Out of stock',
                count: h.outOfStock,
              ),
              const SizedBox(height: 8),
              Text(
                'Low stock means ${h.lowStockThreshold} units or fewer.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      SellerReveal(
        index: 2,
        child: SellerSectionCard(
          icon: Icons.trending_up,
          title: 'Fast moving',
          child: _FastMovingList(group: o.fastMoving),
        ),
      ),
      const SizedBox(height: 16),
      SellerReveal(
        index: 3,
        child: SellerSectionCard(
          icon: Icons.schedule,
          title: 'Expiring soon',
          child: _ExpiryList(
            group: o.expiringSoon,
            emptyText:
                'Nothing expires in the next ${o.expiringSoon.days} days.',
            summaryPrefix: 'Next ${o.expiringSoon.days} days',
          ),
        ),
      ),
      const SizedBox(height: 16),
      SellerReveal(
        index: 4,
        child: SellerSectionCard(
          icon: Icons.event_busy,
          title: 'Expired',
          child: _ExpiryList(
            group: o.expired,
            emptyText: 'Nothing has expired.',
            summaryPrefix: 'Already expired',
          ),
        ),
      ),
    ];
  }
}

// ----------------------------------------------------------------- pieces

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Two columns of tiles; each tile gets half of the width.
class _StatGrid extends StatelessWidget {
  const _StatGrid(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 16,
          children: [for (final t in children) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
  });

  final int inStock;
  final int lowStock;
  final int outOfStock;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    final total = inStock + lowStock + outOfStock;

    Widget segment(int n, Color color) =>
        Expanded(flex: n, child: Container(color: color));

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: total == 0
            ? Container(color: context.colors.surfaceContainerHighest)
            : Row(
                children: [
                  if (inStock > 0) segment(inStock, status.successFg),
                  if (lowStock > 0) segment(lowStock, status.warningFg),
                  if (outOfStock > 0) segment(outOfStock, status.dangerFg),
                ],
              ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.subtitleColor,
    this.last = false,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final Color? subtitleColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor ?? scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                trailing,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: scheme.outlineVariant),
      ],
    );
  }
}

class _FastMovingList extends StatelessWidget {
  const _FastMovingList({required this.group});

  final OverviewGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (group.items.isEmpty) {
      return Text(
        'No sales in the last ${group.days} days.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last ${group.days} days · ${group.units} unit${group.units == 1 ? '' : 's'} sold',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < group.items.length; i++)
          _ItemRow(
            title: group.items[i].name,
            subtitle: [
              '${group.items[i].sharePercent.toStringAsFixed(0)}% of sales',
              '${group.items[i].currentQuantity} left',
              if (group.items[i].daysOfStock != null)
                '~${group.items[i].daysOfStock} days of stock',
            ].join(' · '),
            trailing: '${group.items[i].unitsSold} sold',
            last: i == group.items.length - 1,
          ),
      ],
    );
  }
}

class _ExpiryList extends StatelessWidget {
  const _ExpiryList({
    required this.group,
    required this.emptyText,
    required this.summaryPrefix,
  });

  final OverviewGroup group;
  final String emptyText;
  final String summaryPrefix;

  static final _date = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;

    if (group.items.isEmpty) {
      return Text(
        emptyText,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$summaryPrefix · ${group.itemCount} item${group.itemCount == 1 ? '' : 's'}'
          ' · ${group.units} unit${group.units == 1 ? '' : 's'}'
          ' · ${formatPrice(group.costValue)} at cost',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < group.items.length; i++)
          () {
            final item = group.items[i];
            final left = item.daysLeft;
            final when = item.nextExpiryDate == null
                ? 'Expiry date unknown'
                : 'Expires ${_date.format(item.nextExpiryDate!)}'
                      '${left == null ? '' : ' ($left day${left == 1 ? '' : 's'} left)'}';
            final color = (left != null && left <= 7)
                ? status.dangerFg
                : status.warningFg;
            return _ItemRow(
              title: item.name,
              subtitle: when,
              subtitleColor: color,
              trailing: '${item.units} units',
              last: i == group.items.length - 1,
            );
          }(),
      ],
    );
  }
}