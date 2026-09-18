import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/navigation/full_screen_nav.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/core/widgets/image_action_sheet.dart';
import 'package:yanzee_app/core/widgets/image_preview_screen.dart';
import 'package:yanzee_app/core/widgets/keyboard_safe_sheet.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_store_provider.dart';

class SellerStoreScreen extends ConsumerWidget {
  const SellerStoreScreen({super.key});

  Future<void> _pickLogo(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && context.mounted) {
      ref.read(sellerStoreProvider.notifier).updateLogo(File(picked.path));
    }
  }

  void _showLogoOptions(BuildContext context, WidgetRef ref, File? logoFile) {
    final hasImage = logoFile != null;

    showImageActionSheet(
      context: context,
      hasImage: hasImage,
      onPreview: () {
        if (logoFile == null) return;
        pushFullScreen(
          context,
          ImagePreviewScreen(
            imagePath: logoFile.path,
            onDelete: () =>
                ref.read(sellerStoreProvider.notifier).updateLogo(null),
          ),
        );
      },
      onChange: () => _pickLogo(context, ref),
      onDelete: hasImage
          ? () => ref.read(sellerStoreProvider.notifier).updateLogo(null)
          : null,
    );
  }

  Future<void> _editField({
    required BuildContext context,
    required String label,
    required String currentValue,
    required void Function(String) onSave,
    int maxLines = 1,
  }) async {
    final result = await showKeyboardSafeSheet<String>(
      context: context,
      builder: (ctx) => _EditFieldForm(
        label: label,
        currentValue: currentValue,
        maxLines: maxLines,
      ),
    );

    if (context.mounted && result != null && result.isNotEmpty) {
      onSave(result);
    }
  }

  ImageProvider? _getLogoProvider(File? logoFile) {
    if (logoFile == null) return null;
    return ResizeImage(
      FileImage(logoFile),
      width: 300,
      height: 300,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(sellerStoreProvider);
    final notifier = ref.read(sellerStoreProvider.notifier);
    final logoProvider = _getLogoProvider(store.logoImage);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F2),
        elevation: 0,
        title: const Text(
          'Store',
          style: TextStyle(
            fontFamily: AppFonts.brand,
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/seller-profile'),
            child: const Text(
              'Preview as customer',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                  backgroundImage: logoProvider,
                  child: logoProvider == null
                      ? const Icon(Iconsax.shop, size: 36)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showLogoOptions(context, ref, store.logoImage),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.camera,
                        color: Colors.white,
                        size: 14,
                      ),
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
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Iconsax.arrow_right_3,
                  color: Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditFieldForm extends StatefulWidget {
  final String label;
  final String currentValue;
  final int maxLines;

  const _EditFieldForm({
    required this.label,
    required this.currentValue,
    required this.maxLines,
  });

  @override
  State<_EditFieldForm> createState() => _EditFieldFormState();
}

class _EditFieldFormState extends State<_EditFieldForm> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue == 'Not set' ? '' : widget.currentValue,
    );

    // Prevents focus race condition during sheet animation on Android OEM devices
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit ${widget.label}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: 'Enter ${widget.label}',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}