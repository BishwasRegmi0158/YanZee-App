import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/customer.dart';
import 'package:yanzee_app/data/models/order_draft.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/data/models/sale_item.dart';
import 'package:yanzee_app/data/models/store_order.dart';
import 'package:yanzee_app/data/services/sale_items_api_service.dart';
import 'package:yanzee_app/data/services/store_order_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/order_form_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_filter_chips.dart';
import 'package:yanzee_app/features/seller/widgets/seller_filter_dropdown.dart';

const _stockOptions = <(String, String)>[
  ('In stock only', 'in'),
  ('Include out of stock', 'all'),
];

class StorePosScreen extends ConsumerStatefulWidget {
  const StorePosScreen({super.key});

  @override
  ConsumerState<StorePosScreen> createState() => _StorePosScreenState();
}

class _StorePosScreenState extends ConsumerState<StorePosScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _outletNotifier = ValueNotifier<String?>(null);
  final _stockNotifier = ValueNotifier<String?>('in');
  final List<DraftLine> _lines = [];
  Timer? _debounce;

  String? _outletId;
  bool _includeOutOfStock = false;
  late final SaleItemsLoader _loader = SaleItemsLoader(_fetch);

  Future<SalePage> _fetch(int page) {
    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null) throw Exception('No store loaded.');
    return ref.read(saleItemsApiServiceProvider).fetch(
          storeId,
          channel: StoreOrderChannel.pos,
          outletId: _outletId,
          search: _search.text,
          includeOutOfStock: _includeOutOfStock,
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
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    _outletNotifier.dispose();
    _stockNotifier.dispose();
    _loader.dispose();
    super.dispose();
  }

  /// Picks the main outlet the first time the outlets are known.
  void _ensureOutlet(List<Outlet> outlets) {
    if (_outletId != null || outlets.isEmpty) return;
    final main = outlets.firstWhere((o) => o.isMain, orElse: () => outlets.first);
    _outletId = main.id;
    _outletNotifier.value = main.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loader.reload();
    });
  }

  void _onOutletChanged(String? id) {
    if (id == null || id == _outletId) return;
    setState(() {
      _outletId = id;
      _outletNotifier.value = id;
      if (_lines.isNotEmpty) {
        _lines.clear();
        AppToast.info(context, 'The cart was cleared because the outlet changed');
      }
    });
    _loader.reload();
  }

  void _add(SaleItem i) {
    setState(() {
      final idx = _lines.indexWhere((l) => l.key == i.key);
      if (idx >= 0) {
        final l = _lines[idx];
        if (l.quantity < l.stock) l.quantity++;
      } else {
        _lines.add(DraftLine.fromSale(i));
      }
    });
  }

  int _inCart(SaleItem i) {
    for (final l in _lines) {
      if (l.key == i.key) return l.quantity;
    }
    return 0;
  }

  Future<void> _checkout() async {
    final outletId = _outletId;
    if (outletId == null || _lines.isEmpty) return;
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellerFormTheme(
        child: _CheckoutSheet(lines: _lines, outletId: outletId),
      ),
    );
    if (!mounted) return;
    if (done == true) {
      setState(_lines.clear);
      _loader.reload(); // stock changed
    } else {
      setState(() {}); // lines may have changed in the sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    final outlets = (ref.watch(sellerOutletsProvider).value ?? const <Outlet>[])
        .where((o) => o.isActive)
        .toList();
    _ensureOutlet(outlets);

    final estimate = OrderEstimate.of(
      _lines,
      discountType: 'FIXED',
      discountValue: 0,
      deliveryFee: 0,
    );
    final count = _lines.fold<int>(0, (s, l) => s + l.quantity);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('POS')),
        bottomNavigationBar: _lines.isEmpty
            ? null
            : _CartBar(count: count, total: estimate.total, onPay: _checkout),
        body: ListenableBuilder(
          listenable: _loader,
          builder: (context, _) => ListView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TextField(
                controller: _search,
                onChanged: (_) {
                  setState(() {});
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 400),
                    _loader.reload,
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Search products or SKU',
                  prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                            _loader.reload();
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Outlet on the left, stock filter on the right.
              Row(
                children: [
                  Expanded(
                    child: outlets.isEmpty
                        ? const Text('No active outlet')
                        : SellerFilterDropdown(
                            options: [for (final o in outlets) (o.name, o.id)],
                            notifier: _outletNotifier,
                            onChanged: _onOutletChanged,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SellerFilterDropdown(
                      options: _stockOptions,
                      notifier: _stockNotifier,
                      onChanged: (v) {
                        _stockNotifier.value = v ?? 'in';
                        _includeOutOfStock = v == 'all';
                        _loader.reload();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._items(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _items() {
    if (_outletId == null || (_loader.loading && _loader.items.isEmpty)) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_loader.error != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              children: [
                Text(
                  _loader.error.toString().replaceFirst('Exception: ', ''),
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
        ),
      ];
    }
    if (_loader.items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: Text('No products found')),
        ),
      ];
    }
    return [
      for (final item in _loader.items)
        SaleItemTile(
          key: ValueKey(item.key),
          item: item,
          inCart: _inCart(item),
          onAdd: () => _add(item),
        ),
      if (_loader.loadingMore)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
    ];
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({
    required this.count,
    required this.total,
    required this.onPay,
  });

  final int count;
  final double total;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count item${count == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      formatPrice(total),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onPay,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(150, 48),
                ),
                child: const Text('Review & pay'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- checkout

class _CheckoutSheet extends ConsumerStatefulWidget {
  const _CheckoutSheet({required this.lines, required this.outletId});

  final List<DraftLine> lines;
  final String outletId;

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  final _address = AddressControllers();
  final _note = TextEditingController();
  final _discount = TextEditingController();
  final _received = TextEditingController();

  Customer? _customer;
  String _discountType = 'FIXED';
  String _method = StorePaymentMethod.cash;
  String _payStatus = StorePaymentStatus.paid;
  bool _saving = false;

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    _discount.dispose();
    _received.dispose();
    super.dispose();
  }

  double get _disc => double.tryParse(_discount.text.trim()) ?? 0;

  OrderEstimate get _estimate => OrderEstimate.of(
        widget.lines,
        discountType: _discountType,
        discountValue: _disc,
        deliveryFee: 0,
      );

  Future<void> _pickCustomer() async {
    final c = await showCustomerPicker(context);
    if (c != null && mounted) setState(() => _customer = c);
  }

  Future<void> _submit() async {
    final total = _estimate.total;
    if (_customer == null) {
      AppToast.error(context, 'Choose a customer');
      return;
    }
    if (widget.lines.isEmpty) {
      AppToast.error(context, 'The cart is empty');
      return;
    }
    final received = double.tryParse(_received.text.trim());
    if (_payStatus == StorePaymentStatus.paid &&
        _method == StorePaymentMethod.cash &&
        received != null &&
        received < total) {
      AppToast.error(context, 'The cash received is less than the total');
      return;
    }

    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null) {
      AppToast.error(context, 'No store loaded.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final result = await ref.read(storeOrderApiServiceProvider).createOrder(
            storeId,
            buildOrderBody(
              channel: StoreOrderChannel.pos,
              outletId: widget.outletId,
              customerId: _customer!.id,
              address: _address,
              note: _note.text,
              deliveryFee: 0,
              discountType: _discountType,
              discountValue: _disc,
              paymentMethod: _method,
              paymentStatus: _payStatus,
              lines: widget.lines,
            ),
          );
      invalidateAfterOrder(ref);
      if (!mounted) return;
      AppToast.success(
        context,
        'Order #${result.orderNumber} created successfully',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final est = _estimate;
    final c = _customer;

    final received = double.tryParse(_received.text.trim());
    final change = received == null ? null : received - est.total;
    final showCash =
        _payStatus == StorePaymentStatus.paid && _method == StorePaymentMethod.cash;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.92,
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
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Review order',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    SellerSectionCard(
                      icon: Iconsax.user,
                      title: 'Customer',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c != null) ...[
                            Text(
                              c.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(c.phone ?? c.email ?? ''),
                            const SizedBox(height: 12),
                          ],
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _pickCustomer,
                            icon: const Icon(Icons.search, size: 18),
                            label: Text(
                              c == null ? 'Choose customer' : 'Change customer',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SellerSectionCard(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Cart',
                      child: Column(
                        children: [
                          if (widget.lines.isEmpty)
                            const Text('The cart is empty'),
                          for (final line in widget.lines)
                            DraftLineTile(
                              key: ObjectKey(line),
                              line: line,
                              onChanged: () => setState(() {}),
                              onRemove: () =>
                                  setState(() => widget.lines.remove(line)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SellerSectionCard(
                      icon: Icons.local_offer_outlined,
                      title: 'Extra discount',
                      child: DiscountEditor(
                        type: _discountType,
                        controller: _discount,
                        label: 'Order discount',
                        onTypeChanged: (t) => setState(() => _discountType = t),
                        onValueChanged: () => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SellerSectionCard(
                      icon: Icons.payments_outlined,
                      title: 'Payment',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SellerFilterChips(
                            options: const [
                              ('Cash', StorePaymentMethod.cash),
                              ('COD', StorePaymentMethod.cod),
                            ],
                            selected: _method,
                            onSelected: (v) =>
                                setState(() => _method = v ?? _method),
                          ),
                          const SizedBox(height: 8),
                          SellerFilterChips(
                            options: const [
                              ('Paid', StorePaymentStatus.paid),
                              ('Unpaid', StorePaymentStatus.unpaid),
                            ],
                            selected: _payStatus,
                            onSelected: (v) =>
                                setState(() => _payStatus = v ?? _payStatus),
                          ),
                          if (showCash) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _received,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Cash received (optional)',
                              ),
                            ),
                            if (change != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  change >= 0
                                      ? 'Change to give back: ${formatPrice(change)}'
                                      : 'Still to receive: ${formatPrice(-change)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: change >= 0
                                        ? const Color(0xFF1B7F3A)
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SellerSectionCard(
                      icon: Iconsax.location,
                      title: 'Address and note (optional)',
                      child: Column(
                        children: [
                          AddressFields(controllers: _address, required: false),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _note,
                            minLines: 2,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Order note',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    EstimateCard(estimate: est),
                  ],
                ),
              ),
              SellerBottomBar(
                label: 'Complete order · ${formatPrice(est.total)}',
                saving: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}