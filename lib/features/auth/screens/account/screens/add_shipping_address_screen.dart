import 'package:flutter/material.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/data/models/auth_state.dart';

class AddShippingAddressScreen extends StatefulWidget {
  const AddShippingAddressScreen({super.key, this.address, this.index});

  final ShippingAddress? address;
  final int? index;

  @override
  State<AddShippingAddressScreen> createState() =>
      _AddShippingAddressScreenState();
}

class _AddShippingAddressScreenState extends State<AddShippingAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _street;
  String? _province;

  static const _provinces = [
    'Koshi',
    'Madhesh',
    'Bagmati',
    'Gandaki',
    'Lumbini',
    'Karnali',
    'Sudurpashchim',
  ];

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _name = TextEditingController(text: address?.fullName ?? '');
    _phone = TextEditingController(text: address?.phone ?? '');
    _city = TextEditingController(text: address?.city ?? '');
    _street = TextEditingController(text: address?.street ?? '');
    _province = address?.province;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _street.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _province == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all address fields.')),
      );
      return;
    }
    final address = ShippingAddress(
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      province: _province!,
      city: _city.text.trim(),
      street: _street.text.trim(),
      isDefault: AuthState.instance.addresses.isEmpty,
    );
    if (widget.index == null) {
      AuthState.instance.saveAddress(address);
    } else {
      AuthState.instance.updateAddress(widget.index!, address);
    }
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.address != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(editing ? 'Edit Shipping Address' : 'Add Shipping Address'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              'Full Name',
              _name,
              'Recipient name',
              validator: FormValidators.name,
            ),
            _field(
              'Phone Number',
              _phone,
              '98XXXXXXXX',
              keyboardType: TextInputType.phone,
              validator: FormValidators.phone,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 7),
              child: const Text(
                'Province / Region',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _province,
              decoration: _decoration('Select province'),
              items: _provinces
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _province = value),
              validator: FormValidators.required,
            ),
            _field('City / District', _city, 'e.g. Kathmandu'),
            _field('Street / Area', _street, 'House no, street, area'),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  editing ? 'Update Address' : 'Save Address',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 7),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator ?? FormValidators.required,
            decoration: _decoration(hint),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE1DED9)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE1DED9)),
    ),
  );
}
