import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/checkout/models/checkout_totals.dart';
import 'package:yanzee_app/features/checkout/widgets/cost_summary.dart';

class CheckoutItem {
  const CheckoutItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.items});

  static const routeName = '/checkout';

  final List<CheckoutItem> items;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  String? _province;
  bool _showPayment = false;
  String _paymentMethod = 'Cash on Delivery';

  static const _provinces = [
    'Koshi',
    'Madhesh',
    'Bagmati',
    'Gandaki',
    'Lumbini',
    'Karnali',
    'Sudurpashchim',
  ];

  double get _subtotal => widget.items.fold(
    0,
    (sum, item) => sum + item.product.price * item.quantity,
  );
  CheckoutTotals get _totals => CheckoutTotals.fromSubtotal(_subtotal);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _continueToPayment() {
    if (!_formKey.currentState!.validate()) return;
    if (_province == null) return;
    setState(() => _showPayment = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_showPayment) {
              setState(() => _showPayment = false);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(_showPayment ? 'Payment Method' : 'Checkout'),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: colors.onSurfaceVariant),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: _showPayment ? _paymentBody() : _addressBody(),
      bottomNavigationBar: _showPayment
          ? _paymentBottomBar()
          : _addressBottomBar(),
    );
  }

  Widget _addressBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _sectionCard(
            title: 'Delivery Address',
            icon: Icons.location_on_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Full Name'),
                _field(
                  _nameController,
                  'Recipient name',
                  validator: FormValidators.name,
                ),
                _label('Phone Number'),
                _field(
                  _phoneController,
                  '98XXXXXXXX',
                  keyboardType: TextInputType.phone,
                  validator: FormValidators.phone,
                ),
                _label('Province / Region'),
                DropdownButtonFormField<String>(
                  value: _province,
                  decoration: const InputDecoration(
                    hintText: 'Select province',
                  ),
                  items: _provinces
                      .map(
                        (province) => DropdownMenuItem(
                          value: province,
                          child: Text(province),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _province = value),
                  validator: FormValidators.required,
                ),
                _label('City / District'),
                _field(_cityController, 'e.g. Kathmandu'),
                _label('Street / Area'),
                _field(_streetController, 'House no, street, area'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _orderItemsCard(),
        ],
      ),
    );
  }

  Widget _paymentBody() {
    final colors = context.colors;
    final status = context.status;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        const _UpperLabel('CHOOSE HOW TO PAY'),
        const SizedBox(height: 12),
        _paymentTile(
          title: 'Cash on Delivery',
          subtitle: 'Pay with cash when your order arrives',
          icon: Icons.payments_outlined,
          background: status.successBg,
          foreground: status.successFg,
        ),
        _paymentTile(
          title: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard and more',
          icon: Icons.credit_card_outlined,
          background: status.infoBg,
          foreground: status.infoFg,
        ),
        _paymentTile(
          title: 'eSewa Wallet',
          subtitle: 'Pay via your eSewa balance',
          icon: Icons.account_balance_wallet_outlined,
          background: status.successBg,
          foreground: status.successFg,
        ),
        const SizedBox(height: 28),
        CostSummary(totals: _totals),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Payable',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            ),
            Text(
              formatPrice(_totals.total),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }

  Widget _paymentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    final colors = context.colors;
    final selected = _paymentMethod == title;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = title),
      borderRadius: BorderRadius.circular(AppTheme.r2xl),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.r2xl),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppTheme.rXl),
              ),
              child: Icon(icon, color: foreground),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppTheme.r2xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: context.text.titleLarge?.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _orderItemsCard() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppTheme.r2xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _UpperLabel('ORDER ITEMS'),
          const SizedBox(height: 14),
          for (final item in widget.items) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.rLg),
                  child: Image.network(
                    item.product.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: colors.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${item.product.name}\nQty: ${item.quantity}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatPrice(item.product.price * item.quantity),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (item != widget.items.last) const Divider(height: 24),
          ],
          const SizedBox(height: 16),
          CostSummary(totals: _totals),
        ],
      ),
    );
  }

  Widget _addressBottomBar() {
    return _bottomBar(
      label: 'Add address to continue',
      onPressed: _continueToPayment,
    );
  }

  Widget _paymentBottomBar() {
    return _bottomBar(
      label: 'Place order · ${formatPrice(_totals.total)}',
      onPressed: () => AppToast.success(context, 'Order placed successfully.'),
    );
  }

  Widget _bottomBar({required String label, required VoidCallback onPressed}) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    formatPrice(_totals.total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: onPressed,
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 7),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ?? FormValidators.required,
      // Border, fill and focus colour come from the global input theme.
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _UpperLabel extends StatelessWidget {
  const _UpperLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.colors.onSurfaceVariant,
        fontSize: 11,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}