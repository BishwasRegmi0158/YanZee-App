import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/add_shipping_address_screen.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/choose_address_screen.dart';
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
  bool _saveAddress = true;
  bool _showPayment = false;
  String _paymentMethod = 'Cash on Delivery';
  ShippingAddress? _savedAddress;

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
  void initState() {
    super.initState();
    AuthState.instance.addListener(_onAuthChanged);
    _loadSavedAddress();
  }

  void _onAuthChanged() {
    if (mounted) setState(_loadSavedAddress);
  }

  void _loadSavedAddress() {
    final address = AuthState.instance.defaultAddress;
    if (address == null) return;
    _savedAddress = address;
    _nameController.text = address.fullName;
    _phoneController.text = address.phone;
    _province = address.province;
    _cityController.text = address.city;
    _streetController.text = address.street;
  }

  @override
  void dispose() {
    AuthState.instance.removeListener(_onAuthChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _continueToPayment() {
    if (!_formKey.currentState!.validate()) return;
    if (_province == null) return;
    if (_saveAddress) {
      final address = ShippingAddress(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        province: _province!,
        city: _cityController.text.trim(),
        street: _streetController.text.trim(),
        isDefault: true,
      );
      if (_savedAddress != null && AuthState.instance.addresses.isNotEmpty) {
        AuthState.instance.updateAddress(0, address);
      } else {
        AuthState.instance.saveAddress(address);
      }
      _savedAddress = address;
    }
    setState(() => _showPayment = true);
  }

  Future<void> _chooseAddress() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChooseAddressScreen()));
    if (mounted) setState(_loadSavedAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_showPayment) {
              setState(() => _showPayment = false);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _showPayment ? 'Payment Method' : 'Checkout',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
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
                if (_savedAddress != null) ...[
                  _savedAddressCard(),
                  const SizedBox(height: 8),
                ],
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
                  decoration: _inputDecoration('Select province'),
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
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _saveAddress,
                  onChanged: (value) =>
                      setState(() => _saveAddress = value ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Save this address for next time',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _orderItemsCard(),
        ],
      ),
    );
  }

  Widget _savedAddressCard() {
    final address = _savedAddress!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '${address.fullName} · ${address.phone}\n${address.summary}',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          TextButton(onPressed: _chooseAddress, child: const Text('Change')),
        ],
      ),
    );
  }

  Widget _paymentBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        const _UpperLabel('CHOOSE HOW TO PAY'),
        const SizedBox(height: 12),
        _paymentTile(
          title: 'Cash on Delivery',
          subtitle: 'Pay with cash when your order arrives',
          icon: Icons.payments_outlined,
          color: const Color(0xFFEAF5EB),
        ),
        _paymentTile(
          title: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard and more',
          icon: Icons.credit_card_outlined,
          color: const Color(0xFFEEF2F8),
        ),
        _paymentTile(
          title: 'eSewa Wallet',
          subtitle: 'Pay via your eSewa balance',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFFEAF7E4),
        ),
        const SizedBox(height: 28),
        CostSummary(totals: _totals),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Payable',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            Text(
              '\$${_totals.total.toStringAsFixed(0)}',
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
    required Color color,
  }) {
    final selected = _paymentMethod == title;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.black : const Color(0xFFE2E2E2),
            width: selected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.black54),
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: selected ? Colors.black : Colors.grey.shade400,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E0DC)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E0DC)),
        borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.product.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: const Color(0xFFF2F2F2),
                      child: const Icon(Icons.image_not_supported_outlined),
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
                  '\$${(item.product.price * item.quantity).toStringAsFixed(0)}',
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
      label: 'Place order · \$${_totals.total.toStringAsFixed(0)}',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully.')),
        );
      },
    );
  }

  Widget _bottomBar({required String label, required VoidCallback onPressed}) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '\$${_totals.total.toStringAsFixed(0)}',
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
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 7),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE1DED9)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE1DED9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black),
    ),
  );
}

class _UpperLabel extends StatelessWidget {
  const _UpperLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 11,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
