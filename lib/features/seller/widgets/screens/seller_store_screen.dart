import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_store_provider.dart';

class SellerStoreScreen extends ConsumerWidget {
  const SellerStoreScreen({super.key});

  Future<void> _pickLogo(WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      ref.read(sellerStoreProvider.notifier).updateLogo(File(picked.path));
    }
  }

  Future<void> _editField({
    required BuildContext context,
    required String label,
    required String currentValue,
    required void Function(String) onSave,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: currentValue == 'Not set' ? '' : currentValue);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit $label', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: maxLines,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter $label',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      onSave(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(sellerStoreProvider);
    final notifier = ref.read(sellerStoreProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F2),
        elevation: 0,
        title: const Text('Store',
            style: TextStyle(fontFamily: AppFonts.brand, fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => context.push('/seller-profile'),
            child: const Text('Preview as customer', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  backgroundImage: store.logoImage != null ? FileImage(store.logoImage!) : null,
                  child: store.logoImage == null ? const Icon(Iconsax.shop, size: 36) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _pickLogo(ref),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: const Icon(Iconsax.camera, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _tile(
            context,
            Iconsax.shop,
            'Store name',
            store.name,
            onEdit: (v) => notifier.updateField(name: v),
          ),
          _tile(
            context,
            Iconsax.document_text,
            'Description',
            store.description,
            onEdit: (v) => notifier.updateField(description: v),
            maxLines: 3,
          ),
          _tile(
            context,
            Iconsax.location,
            'Pickup address',
            store.pickupAddress,
            onEdit: (v) => notifier.updateField(pickupAddress: v),
          ),
          _tile(
            context,
            Iconsax.call,
            'Contact number',
            store.contactNumber,
            onEdit: (v) => notifier.updateField(contactNumber: v),
          ),
          _tile(
            context,
            Iconsax.percentage_square,
            'Return policy',
            store.returnPolicy,
            onEdit: (v) => notifier.updateField(returnPolicy: v),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    required void Function(String) onEdit,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _editField(
            context: context,
            label: label,
            currentValue: value,
            onSave: onEdit,
            maxLines: maxLines,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
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
                const Icon(Iconsax.arrow_right_3, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}