
import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';

class SellerStoreScreen extends StatelessWidget {
  const SellerStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F2),
        elevation: 0,
        title: const Text('Store', style: TextStyle(fontFamily: AppFonts.brand, fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                const CircleAvatar(radius: 42, backgroundColor: Colors.white, child: Icon(Icons.storefront, size: 36)),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _tile(Icons.storefront_outlined, 'Store name', 'YanZee Atelier'),
          _tile(Icons.description_outlined, 'Description', 'Handmade Nepali crafts & textiles'),
          _tile(Icons.location_on_outlined, 'Pickup address', 'Not set'),
          _tile(Icons.phone_outlined, 'Contact number', 'Not set'),
          _tile(Icons.percent_outlined, 'Return policy', '7-day returns'),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}