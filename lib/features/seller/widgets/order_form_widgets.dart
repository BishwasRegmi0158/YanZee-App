import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/customer.dart';
import 'package:yanzee_app/data/models/order_draft.dart';
import 'package:yanzee_app/data/models/sale_item.dart';
import 'package:yanzee_app/data/models/store_order.dart';
import 'package:yanzee_app/data/services/customer_api_service.dart';
import 'package:yanzee_app/data/services/sale_items_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_inventory_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_products_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/store_orders_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';

/// 150.0 -> "150", 149.5 -> "149.5"
String fmtInput(double v) =>
    v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toString();

/// Orders change stock and the products list.
void invalidateAfterOrder(WidgetRef ref) {
  ref.invalidate(storeOrdersProvider);
  ref.invalidate(sellerStockProvider);
  ref.invalidate(allStockItemsProvider);
  ref.invalidate(sellerProductsProvider);
}

/// The body of POST /orders, used by the order form and by POS.
Map<String, dynamic> buildOrderBody({
  required String channel,
  String? outletId,
  required String customerId,
  required AddressControllers address,
  String? note,
  required double deliveryFee,
  required String discountType,
  required double discountValue,
  required String paymentMethod,
  required String paymentStatus,
  required List<DraftLine> lines,
}) =>
    {
      'channel': channel,
      if (outletId != null) 'outletId': outletId,
      'customerId': customerId,
      ...address.toJson(),
      if (note != null && note.trim().isNotEmpty) 'orderNote': note.trim(),
      'deliveryFee': deliveryFee,
      if (discountValue > 0)
        'discount': {'type': discountType, 'value': discountValue},
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentReference': null,
      'items': [for (final l in lines) l.toJson()],
    };

// ------------------------------------------------------------ address

class AddressControllers {
  final province = TextEditingController();
  final district = TextEditingController();
  final city = TextEditingController();
  final address = TextEditingController();
  final landmark = TextEditingController();

  void fill(StoreOrderCustomer c) {
    province.text = c.province ?? '';
    district.text = c.district ?? '';
    city.text = c.city ?? '';
    address.text = c.address ?? '';
    landmark.text = c.landmark ?? '';
  }

  /// Only the fields that are filled in.
  Map<String, String> toJson() => {
        for (final e in {
          'province': province,
          'district': district,
          'city': city,
          'address': address,
          'landmark': landmark,
        }.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };

  void dispose() {
    for (final c in [province, district, city, address, landmark]) {
      c.dispose();
    }
  }
}

class AddressFields extends StatelessWidget {
  const AddressFields({
    super.key,
    required this.controllers,
    this.required = true,
  });

  final AddressControllers controllers;
  final bool required;

  String? _req(String? v) =>
      required && (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    final c = controllers;
    return Column(
      children: [
        TextFormField(
          controller: c.province,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Province'),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: c.district,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'District'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: c.city,
                validator: _req,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: required ? 'City *' : 'City',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: c.address,
          validator: _req,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: required ? 'Address *' : 'Address',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: c.landmark,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Landmark'),
        ),
      ],
    );
  }
}

// ----------------------------------------------------- discount and lines

/// Rs / % switch plus the value.
class DiscountEditor extends StatelessWidget {
  const DiscountEditor({
    super.key,
    required this.type,
    required this.controller,
    required this.onTypeChanged,
    required this.onValueChanged,
    this.label = 'Discount',
  });

  final String type;
  final TextEditingController controller;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onValueChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment<String>(value: 'FIXED', label: Text('Rs')),
            ButtonSegment<String>(value: 'PERCENT', label: Text('%')),
          ],
          selected: {type},
          onSelectionChanged: (s) => onTypeChanged(s.first),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onValueChanged(),
            decoration: InputDecoration(labelText: label),
          ),
        ),
      ],
    );
  }
}

/// One product line: quantity, price, discount and a remove button.
class DraftLineTile extends StatefulWidget {
  const DraftLineTile({
    super.key,
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final DraftLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<DraftLineTile> createState() => _DraftLineTileState();
}

class _DraftLineTileState extends State<DraftLineTile> {
  late final TextEditingController _disc = TextEditingController(
    text: widget.line.discountValue > 0 ? fmtInput(widget.line.discountValue) : '',
  );

  @override
  void dispose() {
    _disc.dispose();
    super.dispose();
  }

  void _qty(int delta) {
    final l = widget.line;
    final next = l.quantity + delta;
    if (next < 1 || next > l.stock) return;
    setState(() => l.quantity = next);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = widget.line;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                tooltip: 'Remove',
              ),
            ],
          ),
          Row(
            children: [
              IconButton.outlined(
                visualDensity: VisualDensity.compact,
                onPressed: l.quantity > 1 ? () => _qty(-1) : null,
                icon: const Icon(Icons.remove, size: 18),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '${l.quantity}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton.outlined(
                visualDensity: VisualDensity.compact,
                onPressed: l.quantity < l.stock ? () => _qty(1) : null,
                icon: const Icon(Icons.add, size: 18),
              ),
              const Spacer(),
              Text(
                '${formatPrice(l.unitPrice)} each',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          if (l.stock < 100000 && l.quantity >= l.stock)
            Text(
              'Only ${l.stock} in stock',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          const SizedBox(height: 10),
          DiscountEditor(
            type: l.discountType,
            controller: _disc,
            label: 'Item discount',
            onTypeChanged: (t) {
              setState(() => l.discountType = t);
              widget.onChanged();
            },
            onValueChanged: () {
              l.discountValue = double.tryParse(_disc.text.trim()) ?? 0;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatPrice(l.lineTotal),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// The estimated money of an order.
class EstimateCard extends StatelessWidget {
  const EstimateCard({super.key, required this.estimate});

  final OrderEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );

    return SellerSectionCard(
      icon: Icons.receipt_long_outlined,
      title: 'Order total',
      child: Column(
        children: [
          row('Items', formatPrice(estimate.gross)),
          if (estimate.itemDiscount > 0)
            row('Item discounts', '- ${formatPrice(estimate.itemDiscount)}'),
          if (estimate.orderDiscount > 0)
            row('Order discount', '- ${formatPrice(estimate.orderDiscount)}'),
          if (estimate.delivery > 0)
            row('Delivery fee', formatPrice(estimate.delivery)),
          const Divider(height: 20),
          row('Total', formatPrice(estimate.total), bold: true),
          const SizedBox(height: 2),
          Text(
            'Estimate. The server calculates the final total.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- product list

/// Loads sellable items page by page.
class SaleItemsLoader extends ChangeNotifier {
  SaleItemsLoader(this._fetch);

  final Future<SalePage> Function(int page) _fetch;

  final List<SaleItem> items = [];
  bool loading = false;
  bool loadingMore = false;
  Object? error;
  int _page = 0;
  int _totalPages = 1;
  int _generation = 0;
  bool _disposed = false;

  bool get hasMore => _page < _totalPages;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> reload() async {
    final gen = ++_generation;
    loading = true;
    error = null;
    _notify();
    try {
      final p = await _fetch(1);
      if (gen != _generation) return;
      items
        ..clear()
        ..addAll(p.items);
      _page = p.page;
      _totalPages = p.totalPages;
    } catch (e) {
      if (gen != _generation) return;
      items.clear();
      error = e;
    }
    loading = false;
    _notify();
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    final gen = _generation;
    loadingMore = true;
    _notify();
    try {
      final p = await _fetch(_page + 1);
      if (gen == _generation) {
        items.addAll(p.items);
        _page = p.page;
        _totalPages = p.totalPages;
      }
    } catch (_) {}
    loadingMore = false;
    _notify();
  }
}

class SaleItemTile extends StatelessWidget {
  const SaleItemTile({
    super.key,
    required this.item,
    required this.inCart,
    required this.onAdd,
  });

  final SaleItem item;
  final int inCart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final out = item.quantity <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SellerDetailAvatar(
            url: item.image,
            icon: Icons.inventory_2_outlined,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.sku != null) item.sku!,
                    out ? 'Out of stock' : '${item.quantity} in stock',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: out ? Colors.red.shade700 : scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  formatPrice(item.unitPrice),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (inCart > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '×$inCart',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          IconButton.filled(
            onPressed: out ? null : onAdd,
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'Add',
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to pick products. Picked products are added to [lines].
Future<void> showSaleItemPicker(
  BuildContext context, {
  required String channel,
  String? outletId,
  required List<DraftLine> lines,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SellerFormTheme(
      child: _SaleItemPicker(channel: channel, outletId: outletId, lines: lines),
    ),
  );
}

class _SaleItemPicker extends ConsumerStatefulWidget {
  const _SaleItemPicker({
    required this.channel,
    required this.outletId,
    required this.lines,
  });

  final String channel;
  final String? outletId;
  final List<DraftLine> lines;

  @override
  ConsumerState<_SaleItemPicker> createState() => _SaleItemPickerState();
}

class _SaleItemPickerState extends ConsumerState<_SaleItemPicker> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  late final SaleItemsLoader _loader = SaleItemsLoader(_fetch);

  Future<SalePage> _fetch(int page) {
    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null) throw Exception('No store loaded.');
    return ref.read(saleItemsApiServiceProvider).fetch(
          storeId,
          channel: widget.channel,
          outletId: widget.outletId,
          search: _search.text,
          page: page,
        );
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 300) {
        _loader.loadMore();
      }
    });
    _loader.reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    _loader.dispose();
    super.dispose();
  }

  int _inCart(SaleItem i) {
    for (final l in widget.lines) {
      if (l.key == i.key) return l.quantity;
    }
    return 0;
  }

  void _add(SaleItem i) {
    setState(() {
      final idx = widget.lines.indexWhere((l) => l.key == i.key);
      if (idx >= 0) {
        final l = widget.lines[idx];
        if (l.quantity < l.stock) l.quantity++;
      } else {
        widget.lines.add(DraftLine.fromSale(i));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Material(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add products',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 400),
                      _loader.reload,
                    );
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search products or SKU',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _loader,
                  builder: (context, _) {
                    if (_loader.loading && _loader.items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_loader.error != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _loader.error
                                    .toString()
                                    .replaceFirst('Exception: ', ''),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _loader.reload,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (_loader.items.isEmpty) {
                      return const Center(child: Text('No products found'));
                    }
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount:
                          _loader.items.length + (_loader.loadingMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _loader.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = _loader.items[i];
                        return SaleItemTile(
                          item: item,
                          inCart: _inCart(item),
                          onAdd: () => _add(item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------- customer picker

/// Bottom sheet to find a customer by name, phone or email.
Future<Customer?> showCustomerPicker(BuildContext context) {
  return showModalBottomSheet<Customer>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SellerFormTheme(child: const _CustomerPicker()),
  );
}

class _CustomerPicker extends ConsumerStatefulWidget {
  const _CustomerPicker();

  @override
  ConsumerState<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends ConsumerState<_CustomerPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Customer> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null) {
      setState(() {
        _loading = false;
        _error = 'No store loaded.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(customerApiServiceProvider)
          .getCustomers(storeId, search: _search.text, limit: 20);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Material(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose a customer',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), _load);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by name, phone or email',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _items.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'No customer found.\nAdd one from the Customers page.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _items.length,
                                itemBuilder: (context, i) {
                                  final c = _items[i];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        c.name.isEmpty
                                            ? '?'
                                            : c.name[0].toUpperCase(),
                                      ),
                                    ),
                                    title: Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      [
                                        if (c.phone != null) c.phone!,
                                        if (c.email != null) c.email!,
                                      ].join(' · '),
                                    ),
                                    onTap: () => Navigator.of(context).pop(c),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}