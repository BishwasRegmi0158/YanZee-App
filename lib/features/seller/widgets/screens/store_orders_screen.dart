import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/core/utils/seller_range_calender.dart';
import 'package:yanzee_app/data/models/store_order.dart';
import 'package:yanzee_app/features/seller/widgets/providers/store_orders_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_filter_dropdown.dart';
import 'package:yanzee_app/features/seller/widgets/store_order_widgets.dart';

class StoreOrdersScreen extends ConsumerStatefulWidget {
  const StoreOrdersScreen({super.key});

  @override
  ConsumerState<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends ConsumerState<StoreOrdersScreen> {
  static final _short = DateFormat('dd MMM yyyy');

  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _statusFilter = ValueNotifier<String?>('all');
  final _channelFilter = ValueNotifier<String?>('all');
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    final f = ref.read(storeOrderFilterProvider);
    _searchCtrl.text = f.search;
    _statusFilter.value = f.status ?? 'all';
    _channelFilter.value = f.channel ?? 'all';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scroll.dispose();
    _statusFilter.dispose();
    _channelFilter.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 300) {
      ref.read(storeOrdersProvider.notifier).loadMore();
    }
  }

  void _setFilter(StoreOrderFilter Function(StoreOrderFilter f) change) {
    final notifier = ref.read(storeOrderFilterProvider.notifier);
    notifier.state = change(notifier.state);
  }

  void _onSearchChanged(String value) {
    setState(() {}); // shows or hides the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _setFilter(
        (f) => (
          search: value.trim(),
          status: f.status,
          channel: f.channel,
          range: f.range,
        ),
      );
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    _setFilter(
      (f) => (search: '', status: f.status, channel: f.channel, range: f.range),
    );
    setState(() {});
  }

  void _clearAll() {
    _debounce?.cancel();
    _searchCtrl.clear();
    _statusFilter.value = 'all';
    _channelFilter.value = 'all';
    ref.read(storeOrderFilterProvider.notifier).state = kNoStoreOrderFilter;
    setState(() {});
  }

  Future<void> _pickRange() async {
    final current = ref.read(storeOrderFilterProvider).range;
    final result = await showRangeCalendarSheet(context, initial: current);
    if (result == null || !mounted) return;
    _setFilter(
      (f) => (
        search: f.search,
        status: f.status,
        channel: f.channel,
        range: result.cleared ? null : result.range,
      ),
    );
  }

  /// Opens POS or New order, then reloads the list when the seller comes back.
  Future<void> _open(String path) async {
    await context.push(path);
    if (!mounted) return;
    ref.invalidate(storeOrdersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(storeOrdersProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
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
                      'Failed to load orders: ${e.toString().replaceFirst('Exception: ', '')}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(storeOrdersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          data: (s) => _page(_listBody(s)),
        ),
      ),
    );
  }

  /// Header + search + filters + [body], all in one scrolling list.
  Widget _page(List<Widget> body) {
    final colors = context.colors;
    final range = ref.watch(storeOrderFilterProvider).range;

    Widget pad(Widget w) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: w);

    final statusOptions = <(String, String)>[
      ('All statuses', 'all'),
      for (final s in StoreOrderStatus.values) (prettyEnum(s), s),
    ];
    const channelOptions = <(String, String)>[
      ('All channels', 'all'),
      ('Admin', StoreOrderChannel.admin),
      ('POS', StoreOrderChannel.pos),
    ];

    const compactButton = Size(0, 40);
    const compactPadding = EdgeInsets.symmetric(horizontal: 16);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(storeOrdersProvider.future),
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 12, bottom: 90),
        children: [
          pad(
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orders',
                        style: context.text.headlineLarge?.copyWith(
                          fontSize: Responsive.font(context, 24),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Admin dashboard and POS orders',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Responsive.font(context, 12),
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _open('/seller/orders/pos'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: compactButton,
                    padding: compactPadding,
                  ),
                  child: const Text('POS'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _open('/seller/orders/new'),
                  style: FilledButton.styleFrom(
                    minimumSize: compactButton,
                    padding: compactPadding,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          pad(_searchField()),
          const SizedBox(height: 10),
          pad(
            Row(
              children: [
                Expanded(
                  child: SellerFilterDropdown(
                    options: statusOptions,
                    notifier: _statusFilter,
                    onChanged: (v) {
                      _statusFilter.value = v ?? 'all';
                      _setFilter(
                        (f) => (
                          search: f.search,
                          status: (v == null || v == 'all') ? null : v,
                          channel: f.channel,
                          range: f.range,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SellerFilterDropdown(
                    options: channelOptions,
                    notifier: _channelFilter,
                    onChanged: (v) {
                      _channelFilter.value = v ?? 'all';
                      _setFilter(
                        (f) => (
                          search: f.search,
                          status: f.status,
                          channel: (v == null || v == 'all') ? null : v,
                          range: f.range,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          pad(
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
                    // Same height as the dropdowns above it.
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                  ),
                ),
                if (range != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _setFilter(
                      (f) => (
                        search: f.search,
                        status: f.status,
                        channel: f.channel,
                        range: null,
                      ),
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          pad(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Name, phone, order # or email',
        prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clearSearch,
                icon: const Icon(Icons.close, size: 18),
              ),
      ),
    );
  }

  List<Widget> _listBody(StoreOrdersState s) {
    final colors = context.colors;
    final active = ref.watch(storeOrderFilterProvider) != kNoStoreOrderFilter;
    final items = s.items;

    return [
      Row(
        children: [
          Expanded(
            child: Text(
              '${s.total} order${s.total == 1 ? '' : 's'}'
              '${active ? ' found' : ''}',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ),
          if (active)
            GestureDetector(
              onTap: _clearAll,
              child: Text(
                'Clear filters',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Iconsax.receipt_2, size: 44, color: colors.outline),
              const SizedBox(height: 10),
              Text(
                active ? 'No orders match your filters' : 'No orders yet',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        )
      else
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.r2xl),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
                _OrderRow(
                  order: items[i],
                  onTap: () => context.push(
                    '/seller/orders/detail',
                    extra: items[i].id,
                  ),
                ),
              ],
            ],
          ),
        ),
      if (s.loadingMore)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
    ];
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.onTap});

  final StoreOrderRow order;
  final VoidCallback onTap;

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final created = order.createdAt == null
        ? null
        : _dateFmt.format(order.createdAt!.toLocal());
    final who = [
      order.customerName,
      if (order.customerPhone != null) order.customerPhone!,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: Responsive.font(context, 15),
                  ),
                ),
                const SizedBox(width: 8),
                StoreChannelPill(order.channel),
                const Spacer(),
                StoreOrderStatusPill(order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              who,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.font(context, 13),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  formatPrice(order.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.font(context, 14),
                  ),
                ),
                const SizedBox(width: 8),
                StorePaymentPill(order.paymentStatus),
                const Spacer(),
                Text(
                  '${order.totalQuantity} item${order.totalQuantity == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 12),
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (created != null) ...[
              const SizedBox(height: 4),
              Text(
                created,
                style: TextStyle(
                  fontSize: Responsive.font(context, 11.5),
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}