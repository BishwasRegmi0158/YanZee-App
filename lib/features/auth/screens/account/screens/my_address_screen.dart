import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

/// No address API exists yet (DummyJSON has none) — this screen manages
/// addresses in local state only. Swap `_addresses` for a real
/// repository call once there's a backend endpoint for it.
class Address {
  Address({
    required this.label,
    required this.line,
    required this.region,
    this.isDefault = false,
  });

  final String label;
  final String line;
  final String region;
  final bool isDefault;
}

class MyAddressScreen extends StatefulWidget {
  const MyAddressScreen({super.key});

  @override
  State<MyAddressScreen> createState() => _MyAddressScreenState();
}

class _MyAddressScreenState extends State<MyAddressScreen> {
  final List<Address> _addresses = [
    Address(
      label: 'Home',
      line: 'House 24, Jhamsikhel, Lalitpur',
      region: 'Bagmati, Nepal',
      isDefault: true,
    ),
    Address(
      label: 'Work',
      line: 'YanZee HQ, Durbar Marg',
      region: 'Kathmandu, Nepal',
    ),
  ];

  Future<void> _addAddress() async {
    final labelController = TextEditingController();
    final lineController = TextEditingController();
    final regionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add new address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label (e.g. Home)')),
            TextField(controller: lineController, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: regionController, decoration: const InputDecoration(labelText: 'City / Province')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );

    if (result == true && lineController.text.trim().isNotEmpty) {
      setState(() {
        _addresses.add(Address(
          label: labelController.text.trim().isEmpty ? 'Address' : labelController.text.trim(),
          line: lineController.text.trim(),
          region: regionController.text.trim(),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        title: const Text('My Address', style: TextStyle(color: AuthColors.textDark)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final address in _addresses) _addressCard(address),
            InkWell(
              onTap: _addAddress,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AuthColors.borderDefault, style: BorderStyle.solid),
                ),
                alignment: Alignment.center,
                child: const Text('+ Add new address', style: TextStyle(fontWeight: FontWeight.w600, color: AuthColors.textDark)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressCard(Address address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(address.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AuthColors.textDark)),
              if (address.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                  child: const Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(address.line, style: const TextStyle(fontSize: 13, color: AuthColors.textDark)),
          const SizedBox(height: 2),
          Text(address.region, style: const TextStyle(fontSize: 12, color: Color(0xFF9A9A9A))),
        ],
      ),
    );
  }
}