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
import 'package:yanzee_app/data/models/seller_store.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_store_provider.dart';

class SellerStoreScreen extends ConsumerWidget {
  const SellerStoreScreen({super.key});

  /// Runs a save and shows the error (if any) in a snackbar.
  Future<void> _save(
    BuildContext context,
    Future<String?> Function() action,
  ) async {
    final error = await action();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _pickLogo(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && context.mounted) {
      final notifier = ref.read(sellerStoreProvider.notifier);
      _save(context, () => notifier.updateLogo(File(picked.path)));
    }
  }

  void _previewLogo(BuildContext context, WidgetRef ref, SellerStore store) {
    final notifier = ref.read(sellerStoreProvider.notifier);
    final file = store.logoImage;
    final url = store.logoUrl;

    if (file != null) {
      pushFullScreen(
        context,
        ImagePreviewScreen(
          imagePath: file.path,
          onDelete: () => _save(context, () => notifier.removeLogo()),
        ),
      );
    } else if (url != null) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      );
    }
  }

  void _showLogoOptions(BuildContext context, WidgetRef ref, SellerStore store) {
    final hasImage = store.logoImage != null || store.logoUrl != null;
    final notifier = ref.read(sellerStoreProvider.notifier);

    showImageActionSheet(
      context: context,
      hasImage: hasImage,
      onPreview: () => _previewLogo(context, ref, store),
      onChange: () => _pickLogo(context, ref),
      onDelete: hasImage
          ? () => _save(context, () => notifier.removeLogo())
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

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to open your shop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Log out',
              style: TextStyle(color: Color(0xFFE05A47)),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    // POST /auth/logout, clears the saved refresh token and AuthState
    await AuthService.logout();
    if (!context.mounted) return;

    // The user is no longer a shop owner, so go to the customer home.
    context.go('/home');
  }

  /// A freshly picked file wins (instant preview); otherwise the saved URL.
  ImageProvider? _getLogoProvider(SellerStore store) {
    if (store.logoImage != null) {
      return ResizeImage(FileImage(store.logoImage!), width: 300, height: 300);
    }
    if (store.logoUrl != null) {
      return ResizeImage(NetworkImage(store.logoUrl!), width: 300, height: 300);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(sellerStoreProvider);
    final notifier = ref.read(sellerStoreProvider.notifier);
    final logoProvider = _getLogoProvider(store);

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
                    onTap: () => _showLogoOptions(context, ref, store),
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
            onEdit: (v) => _save(context, () => notifier.updateField(name: v)),
          ),
          _tile(
            context,
            Iconsax.document_text,
            'Description',
            store.description,
            onEdit: (v) =>
                _save(context, () => notifier.updateField(description: v)),
            maxLines: 3,
          ),
          _tile(
            context,
            Iconsax.sms,
            'Contact email',
            store.contactEmail,
            onEdit: (v) =>
                _save(context, () => notifier.updateField(contactEmail: v)),
          ),
          _tile(
            context,
            Iconsax.location,
            'Pickup address',
            store.address,
            onEdit: (v) =>
                _save(context, () => notifier.updateField(address: v)),
            maxLines: 2,
          ),
          _tile(
            context,
            Iconsax.call,
            'Contact number',
            store.contactPhone,
            onEdit: (v) =>
                _save(context, () => notifier.updateField(contactPhone: v)),
          ),
          _tile(
            context,
            Iconsax.percentage_square,
            'Return policy',
            store.returnPolicy,
            onEdit: (v) =>
                _save(context, () => notifier.updateField(returnPolicy: v)),
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _logoutButton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    const red = Color(0xFFE05A47);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Iconsax.logout, size: 18, color: red),
        label: const Text(
          'Log out',
          style: TextStyle(color: red, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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