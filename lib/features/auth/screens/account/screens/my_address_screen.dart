import 'package:flutter/material.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/add_shipping_address_screen.dart';

class MyAddressScreen extends StatefulWidget {
  const MyAddressScreen({super.key});

  @override
  State<MyAddressScreen> createState() => _MyAddressScreenState();
}

class _MyAddressScreenState extends State<MyAddressScreen> {
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

  Future<void> _openEditor({ShippingAddress? address, int? index}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AddShippingAddressScreen(address: address, index: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addresses = AuthState.instance.addresses;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      appBar: AppBar(
        title: const Text('My Address'),
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
            _addressCard(addresses[i], i),
          OutlinedButton.icon(
            onPressed: () => _openEditor(),
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

  Widget _addressCard(ShippingAddress address, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E0DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (address.isDefault)
                const Chip(
                  label: Text(
                    'DEFAULT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              IconButton(
                onPressed: () => _openEditor(address: address, index: index),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
            ],
          ),
          Text(address.phone, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(address.summary),
        ],
      ),
    );
  }
}
