import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/order_draft.dart';
import 'package:yanzee_app/data/models/store_order.dart';
import 'package:yanzee_app/data/services/store_order_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/order_form_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/store_orders_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_filter_chips.dart';

// ------------------------------------------------------ items and payment

class StoreOrderEditSummaryScreen extends ConsumerStatefulWidget {
  const StoreOrderEditSummaryScreen({super.key, required this.order});

  final StoreOrderDetail order;

  @override
  ConsumerState<StoreOrderEditSummaryScreen> createState() =>
      _StoreOrderEditSummaryScreenState();
}

class _StoreOrderEditSummaryScreenState
    extends ConsumerState<StoreOrderEditSummaryScreen> {
  late final List<DraftLine> _lines =
      widget.order.summary.items.map(DraftLine.fromOrderLine).toList();

  late final _delivery = TextEditingController(
    text: widget.order.summary.deliveryFee > 0
        ? fmtInput(widget.order.summary.deliveryFee)
        : '',
  );
  late final _discount = TextEditingController(
    text: widget.order.summary.orderDiscountValue > 0
        ? fmtInput(widget.order.summary.orderDiscountValue)
        : '',
  );
  late final _paid = TextEditingController(
    text: widget.order.summary.paidAmount > 0
        ? fmtInput(widget.order.summary.paidAmount)
        : '',
  );
  final _reference = TextEditingController();

  late String _discountType =
      widget.order.summary.orderDiscountType == 'PERCENT' ? 'PERCENT' : 'FIXED';
  late String _payStatus =
      StorePaymentStatus.values.contains(widget.order.paymentStatus)
          ? widget.order.paymentStatus
          : StorePaymentStatus.unpaid;
  bool _saving = false;

  @override
  void dispose() {
    _delivery.dispose();
    _discount.dispose();
    _paid.dispose();
    _reference.dispose();
    super.dispose();
  }

  double get _fee => double.tryParse(_delivery.text.trim()) ?? 0;
  double get _disc => double.tryParse(_discount.text.trim()) ?? 0;

  Future<void> _addProducts() async {
    await showSaleItemPicker(
      context,
      channel: widget.order.channel == StoreOrderChannel.pos
          ? StoreOrderChannel.pos
          : StoreOrderChannel.admin,
      outletId: widget.order.channel == StoreOrderChannel.pos
          ? widget.order.outletId
          : null,
      lines: _lines,
    );
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_lines.isEmpty) {
      AppToast.error(context, 'An order needs at least one product');
      return;
    }
    double? paid;
    if (_payStatus == StorePaymentStatus.partial) {
      paid = double.tryParse(_paid.text.trim());
      if (paid == null || paid <= 0) {
        AppToast.error(context, 'Enter the amount that was paid');
        return;
      }
    }

    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null) {
      AppToast.error(context, 'No store loaded.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ref.read(storeOrderApiServiceProvider).updateSummary(
        storeId,
        widget.order.id,
        {
          'items': [for (final l in _lines) l.toJson()],
          'deliveryFee': _fee,
          if (_disc > 0) 'discount': {'type': _discountType, 'value': _disc},
          'paymentStatus': _payStatus,
          if (paid != null) 'paidAmount': paid,
          if (_reference.text.trim().isNotEmpty)
            'paymentReference': _reference.text.trim(),
        },
      );
      ref.invalidate(storeOrderDetailProvider(widget.order.id));
      invalidateAfterOrder(ref);
      if (!mounted) return;
      AppToast.success(context, 'Order updated successfully');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimate = OrderEstimate.of(
      _lines,
      discountType: _discountType,
      discountValue: _disc,
      deliveryFee: _fee,
    );

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: Text('Edit order #${widget.order.orderNumber}')),
        bottomNavigationBar: SellerBottomBar(
          label: 'Save changes',
          saving: _saving,
          onPressed: _save,
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SellerSectionCard(
              icon: Icons.inventory_2_outlined,
              title: 'Products (${_lines.length})',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final line in _lines)
                    DraftLineTile(
                      key: ObjectKey(line),
                      line: line,
                      onChanged: () => setState(() {}),
                      onRemove: () => setState(() => _lines.remove(line)),
                    ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _addProducts,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add products'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SellerSectionCard(
              icon: Icons.local_offer_outlined,
              title: 'Delivery fee and discount',
              child: Column(
                children: [
                  TextField(
                    controller: _delivery,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Delivery fee'),
                  ),
                  const SizedBox(height: 16),
                  DiscountEditor(
                    type: _discountType,
                    controller: _discount,
                    label: 'Order discount',
                    onTypeChanged: (t) => setState(() => _discountType = t),
                    onValueChanged: () => setState(() {}),
                  ),
                ],
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
                      ('Unpaid', StorePaymentStatus.unpaid),
                      ('Partial paid', StorePaymentStatus.partial),
                      ('Paid', StorePaymentStatus.paid),
                    ],
                    selected: _payStatus,
                    onSelected: (v) =>
                        setState(() => _payStatus = v ?? _payStatus),
                  ),
                  if (_payStatus == StorePaymentStatus.partial) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _paid,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount paid',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reference,
                    decoration: const InputDecoration(
                      labelText: 'Payment reference (optional)',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            EstimateCard(estimate: estimate),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- customer

class StoreOrderEditCustomerScreen extends ConsumerStatefulWidget {
  const StoreOrderEditCustomerScreen({super.key, required this.order});

  final StoreOrderDetail order;

  @override
  ConsumerState<StoreOrderEditCustomerScreen> createState() =>
      _StoreOrderEditCustomerScreenState();
}

class _StoreOrderEditCustomerScreenState
    extends ConsumerState<StoreOrderEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = AddressControllers();
  late final _name = TextEditingController(text: widget.order.customer.name ?? '');
  late final _phone = TextEditingController(text: widget.order.customer.phone ?? '');
  late final _email = TextEditingController(text: widget.order.customer.email ?? '');
  late final _customerNote =
      TextEditingController(text: widget.order.customer.customerNote ?? '');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _address.fill(widget.order.customer);
  }

  @override
  void dispose() {
    _address.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _customerNote.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null) {
      AppToast.error(context, 'No store loaded.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ref.read(storeOrderApiServiceProvider).updateCustomer(
        storeId,
        widget.order.id,
        {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
          ..._address.toJson(),
          if (_customerNote.text.trim().isNotEmpty)
            'customerNote': _customerNote.text.trim(),
        },
      );
      ref.invalidate(storeOrderDetailProvider(widget.order.id));
      ref.invalidate(storeOrdersProvider);
      if (!mounted) return;
      AppToast.success(context, 'Customer details updated successfully');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Customer · order #${widget.order.orderNumber}'),
        ),
        bottomNavigationBar: SellerBottomBar(
          label: 'Save changes',
          saving: _saving,
          onPressed: _save,
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SellerSectionCard(
                icon: Iconsax.user,
                title: 'Customer',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'This field is required'
                          : null,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phone,
                      validator: (v) => RegExp(r'^\d{10}$').hasMatch((v ?? '').trim())
                          ? null
                          : 'Enter a valid 10-digit phone number',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return null;
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
                            ? null
                            : 'Enter a valid email';
                      },
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SellerSectionCard(
                icon: Iconsax.location,
                title: 'Delivery address',
                child: AddressFields(controllers: _address, required: false),
              ),
              const SizedBox(height: 16),
              SellerSectionCard(
                icon: Icons.sticky_note_2_outlined,
                title: 'Customer note',
                child: TextFormField(
                  controller: _customerNote,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}