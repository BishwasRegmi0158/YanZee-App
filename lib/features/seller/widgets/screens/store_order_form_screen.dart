import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/customer.dart';
import 'package:yanzee_app/data/models/order_draft.dart';
import 'package:yanzee_app/data/models/store_order.dart';
import 'package:yanzee_app/data/services/store_order_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/order_form_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_filter_chips.dart';

class StoreOrderFormScreen extends ConsumerStatefulWidget {
  const StoreOrderFormScreen({super.key});

  @override
  ConsumerState<StoreOrderFormScreen> createState() =>
      _StoreOrderFormScreenState();
}

class _StoreOrderFormScreenState extends ConsumerState<StoreOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = AddressControllers();
  final _note = TextEditingController();
  final _delivery = TextEditingController();
  final _discount = TextEditingController();
  final List<DraftLine> _lines = [];

  Customer? _customer;
  String _discountType = 'FIXED';
  String _method = StorePaymentMethod.cod;
  String _payStatus = StorePaymentStatus.unpaid;
  bool _saving = false;

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    _delivery.dispose();
    _discount.dispose();
    super.dispose();
  }

  double get _fee => double.tryParse(_delivery.text.trim()) ?? 0;
  double get _disc => double.tryParse(_discount.text.trim()) ?? 0;

  Future<void> _pickCustomer() async {
    final c = await showCustomerPicker(context);
    if (c != null && mounted) setState(() => _customer = c);
  }

  Future<void> _addProducts() async {
    await showSaleItemPicker(
      context,
      channel: StoreOrderChannel.admin,
      lines: _lines,
    );
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (_customer == null) {
      AppToast.error(context, 'Choose a customer');
      return;
    }
    if (_lines.isEmpty) {
      AppToast.error(context, 'Add at least one product');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

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
              channel: StoreOrderChannel.admin,
              customerId: _customer!.id,
              address: _address,
              note: _note.text,
              deliveryFee: _fee,
              discountType: _discountType,
              discountValue: _disc,
              paymentMethod: _method,
              paymentStatus: _payStatus,
              lines: _lines,
            ),
          );
      invalidateAfterOrder(ref);
      if (!mounted) return;
      AppToast.success(
        context,
        'Order #${result.orderNumber} created successfully',
      );
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
    final c = _customer;

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('New order')),
        bottomNavigationBar: SellerBottomBar(
          label: 'Create order',
          saving: _saving,
          onPressed: _submit,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                      Text(
                        [
                          if (c.phone != null) c.phone!,
                          if (c.email != null) c.email!,
                        ].join(' · '),
                      ),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickCustomer,
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(c == null ? 'Choose customer' : 'Change customer'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                icon: Iconsax.location,
                title: 'Delivery details',
                child: Column(
                  children: [
                    AddressFields(controllers: _address),
                    const SizedBox(height: 16),
                    TextFormField(
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
                      decoration: const InputDecoration(
                        labelText: 'Delivery fee',
                      ),
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
                    const Text('Method'),
                    const SizedBox(height: 8),
                    SellerFilterChips(
                      options: const [
                        ('Cash', StorePaymentMethod.cash),
                        ('COD', StorePaymentMethod.cod),
                      ],
                      selected: _method,
                      onSelected: (v) => setState(() => _method = v ?? _method),
                    ),
                    const SizedBox(height: 12),
                    const Text('Payment status'),
                    const SizedBox(height: 8),
                    SellerFilterChips(
                      options: const [
                        ('Unpaid', StorePaymentStatus.unpaid),
                        ('Paid', StorePaymentStatus.paid),
                      ],
                      selected: _payStatus,
                      onSelected: (v) =>
                          setState(() => _payStatus = v ?? _payStatus),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              EstimateCard(estimate: estimate),
            ],
          ),
        ),
      ),
    );
  }
}