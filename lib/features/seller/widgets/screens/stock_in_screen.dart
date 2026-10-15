import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/inventory.dart';
import 'package:yanzee_app/data/services/inventory_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_inventory_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_products_provider.dart';

/// One item row of the form.
class _Line {
  final Key key = UniqueKey();
  StockItem? item;
  final TextEditingController qty = TextEditingController();
  final TextEditingController cost = TextEditingController();
  final TextEditingController lot = TextEditingController();
  DateTime? mfg;
  DateTime? exp;

  void dispose() {
    qty.dispose();
    cost.dispose();
    lot.dispose();
  }
}

class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  final _supplier = TextEditingController();
  final _note = TextEditingController();
  final List<_Line> _lines = [_Line()];
  String? _outletId;
  bool _saving = false;

  @override
  void dispose() {
    _reference.dispose();
    _supplier.dispose();
    _note.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _snack(String message) => AppToast.error(context, message);

  String? _blank(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _pickItem(_Line line) async {
    List<StockItem> items;
    try {
      items = await ref.read(sellerStockProvider.future);
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
      return;
    }
    if (!mounted) return;

    final picked = await showModalBottomSheet<StockItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellerFormTheme(child: _ItemPickerSheet(items: items)),
    );
    if (picked != null && mounted) setState(() => line.item = picked);
  }

  Future<void> _pickDate(_Line line, {required bool manufacture}) async {
    final current = manufacture ? line.mfg : line.exp;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (manufacture) {
        line.mfg = picked;
      } else {
        line.exp = picked;
      }
    });
  }

  void _addLine() => setState(() => _lines.add(_Line()));

  void _removeLine(_Line line) {
    setState(() => _lines.remove(line));
    line.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    for (var i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      if (l.item == null) {
        _snack('Select a product for item ${i + 1}');
        return;
      }
      if (l.mfg != null && l.exp != null && l.exp!.isBefore(l.mfg!)) {
        _snack('Item ${i + 1}: expiry date is before the manufacture date');
        return;
      }
    }

    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null || storeId.isEmpty) {
      _snack('No store loaded.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      await ref.read(inventoryApiServiceProvider).stockIn(
            storeId,
            outletId: _outletId!,
            referenceNumber: _blank(_reference.text),
            supplierName: _blank(_supplier.text),
            note: _blank(_note.text),
            items: [
              for (final l in _lines)
                StockInLine(
                  productId: l.item!.productId,
                  variantId: l.item!.variantId,
                  quantity: int.parse(l.qty.text.trim()),
                  unitCost: double.parse(l.cost.text.trim()),
                  supplierLot: _blank(l.lot.text),
                  manufactureDate: l.mfg,
                  expiryDate: l.exp,
                ),
            ],
          );

      // Stock, history and the Products tab all show new numbers now.
      ref.invalidate(sellerStockProvider);
      ref.invalidate(stockMovementsProvider);
      ref.invalidate(sellerProductsProvider);

      if (!mounted) return;
      AppToast.success(context, 'Stock added successfully');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the product list loaded for the picker.
    ref.watch(sellerStockProvider);
    final outletsAsync = ref.watch(sellerOutletsProvider);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Stock in')),
        body: outletsAsync.when(
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
                    onPressed: () => ref.invalidate(sellerOutletsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (all) {
            final outlets = all.where((o) => o.isActive).toList();
            if (outlets.isEmpty) return const _NoOutlet();

            _outletId ??=
                outlets.firstWhere((o) => o.isMain, orElse: () => outlets.first).id;

            return Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  Expanded(
                    // Not a lazy ListView, so every field is validated.
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SellerSectionCard(
                            icon: Iconsax.location,
                            title: 'Receiving outlet',
                            child: DropdownButtonFormField<String>(
                              initialValue: _outletId,
                              isExpanded: true,
                              decoration:
                                  const InputDecoration(labelText: 'Outlet'),
                              items: [
                                for (final o in outlets)
                                  DropdownMenuItem(
                                    value: o.id,
                                    child: Text(
                                      o.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: _saving
                                  ? null
                                  : (v) => setState(() => _outletId = v),
                              validator: (v) =>
                                  v == null ? 'Select an outlet' : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SellerSectionCard(
                            icon: Iconsax.document_text,
                            title: 'Details (optional)',
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _reference,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Reference number',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _supplier,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Supplier name',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _note,
                                  minLines: 2,
                                  maxLines: 3,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    labelText: 'Note',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (var i = 0; i < _lines.length; i++) ...[
                            _LineCard(
                              key: _lines[i].key,
                              index: i,
                              line: _lines[i],
                              canRemove: _lines.length > 1,
                              enabled: !_saving,
                              onPickItem: () => _pickItem(_lines[i]),
                              onPickDate: (manufacture) =>
                                  _pickDate(_lines[i], manufacture: manufacture),
                              onClearDate: (manufacture) => setState(() {
                                if (manufacture) {
                                  _lines[i].mfg = null;
                                } else {
                                  _lines[i].exp = null;
                                }
                              }),
                              onRemove: () => _removeLine(_lines[i]),
                            ),
                            const SizedBox(height: 16),
                          ],
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _addLine,
                            icon: const Icon(Iconsax.add, size: 18),
                            label: const Text('Add another item'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SellerBottomBar(
                    label: 'Add stock',
                    saving: _saving,
                    onPressed: _submit,
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

class _NoOutlet extends StatelessWidget {
  const _NoOutlet();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You need an active outlet before you can add stock.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/seller/outlets/add'),
              child: const Text('Add outlet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    super.key,
    required this.index,
    required this.line,
    required this.canRemove,
    required this.enabled,
    required this.onPickItem,
    required this.onPickDate,
    required this.onClearDate,
    required this.onRemove,
  });

  final int index;
  final _Line line;
  final bool canRemove;
  final bool enabled;
  final VoidCallback onPickItem;
  final ValueChanged<bool> onPickDate; // true = manufacture date
  final ValueChanged<bool> onClearDate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SellerSectionCard(
      icon: Icons.inventory_2_outlined,
      title: 'Item ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: enabled ? onPickItem : null,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              isEmpty: line.item == null,
              decoration: const InputDecoration(
                labelText: 'Product',
                suffixIcon: Icon(Iconsax.arrow_down_1, size: 18),
              ),
              child: Text(
                line.item?.name ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: line.qty,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return (n == null || n <= 0) ? 'Enter a quantity' : null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: line.cost,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Unit cost'),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    return (n == null || n < 0) ? 'Enter a valid cost' : null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: line.lot,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Supplier lot (optional)',
            ),
          ),
          const SizedBox(height: 16),
          _DateField(
            label: 'Manufacture date (optional)',
            value: line.mfg,
            onTap: enabled ? () => onPickDate(true) : null,
            onClear: () => onClearDate(true),
          ),
          const SizedBox(height: 16),
          _DateField(
            label: 'Expiry date (optional)',
            value: line.exp,
            onTap: enabled ? () => onPickDate(false) : null,
            onClear: () => onClearDate(false),
          ),
          if (canRemove) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: enabled ? onRemove : null,
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                icon: const Icon(Iconsax.trash, size: 18),
                label: const Text('Remove item'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final VoidCallback onClear;

  static final _fmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                ),
        ),
        child: Text(value == null ? '' : _fmt.format(value!)),
      ),
    );
  }
}

/// Bottom sheet to search and pick a product / variant.
class _ItemPickerSheet extends StatefulWidget {
  const _ItemPickerSheet({required this.items});

  final List<StockItem> items;

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final q = _q.trim().toLowerCase();
    final list = widget.items
        .where(
          (s) =>
              q.isEmpty ||
              s.name.toLowerCase().contains(q) ||
              (s.sku ?? '').toLowerCase().contains(q),
        )
        .toList();

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
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  decoration: const InputDecoration(
                    hintText: 'Search products or SKU',
                    prefixIcon: Icon(Iconsax.search_normal_1, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final s = list[i];
                          return ListTile(
                            title: Text(
                              s.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (s.sku != null) s.sku!,
                                'In stock: ${s.quantity}',
                              ].join(' · '),
                            ),
                            onTap: () => Navigator.of(context).pop(s),
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