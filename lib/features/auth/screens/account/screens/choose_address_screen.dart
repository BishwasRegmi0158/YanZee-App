import 'package:flutter/material.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/add_shipping_address_screen.dart';

class ChooseAddressScreen extends StatefulWidget {
  const ChooseAddressScreen({super.key});

  @override
  State<ChooseAddressScreen> createState() => _ChooseAddressScreenState();
}

class _ChooseAddressScreenState extends State<ChooseAddressScreen> {
  @override
  void initState() {
    super.initState();
    AuthState.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AuthState.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _choose(int index) {
    AuthState.instance.setDefaultAddress(index);
    Navigator.of(context).pop();
  }

  Future<void> _addNew() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddShippingAddressScreen()),
    );
    // The newly added address is already the default (see AddShippingAddressScreen),
    // so once it comes back we can just close the picker too.
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final addresses = AuthState.instance.addresses;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      appBar: AppBar(
        title: const Text('Choose Address'),
        backgroundColor: const Color(0xFFF8F7F5),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: Center(
                child: Text(
                  'No saved shipping address yet.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          for (var i = 0; i < addresses.length; i++)
            _addressTile(addresses[i], i),
          OutlinedButton.icon(
            onPressed: _addNew,
            icon: const Icon(Icons.add),
            label: const Text('Add new address'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.black26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressTile(ShippingAddress address, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault ? Colors.black : const Color(0xFFE3E0DC),
          width: address.isDefault ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _choose(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                address.isDefault
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: address.isDefault ? Colors.black : Colors.black38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${address.fullName} · ${address.phone}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.summary,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}