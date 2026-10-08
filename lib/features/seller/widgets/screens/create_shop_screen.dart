import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

class CreateShopScreen extends ConsumerStatefulWidget {
  /// true when opened from the drawer to add another shop.
  final bool isAdditional;
  const CreateShopScreen({super.key, this.isAdditional = false});

  @override
  ConsumerState<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends ConsumerState<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  late final TextEditingController _email =
      TextEditingController(text: AuthState.instance.user?.email ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: AuthState.instance.user?.phone ?? '');
  String? _category;
  File? _logo;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) setState(() => _logo = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final api = ref.read(shopApiServiceProvider);
      final shop = await api.createShop(
        name: _name.text.trim(),
        category: _category!,
        contactEmail: _email.text.trim(),
        contactPhone: _phone.text.trim(),
        storeAddress: _address.text.trim(),
      );

      // Optional logo: the server saves it on the store that was just made.
      if (_logo != null) {
        try {
          await api.uploadStoreLogo(shop.id, _logo!);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Store created, but the logo could not be uploaded. '
                  'You can add it later in the Store tab.',
                ),
              ),
            );
          }
        }
      }

      if (widget.isAdditional) {
        if (!mounted) return;
        // Make the new shop the active one, then reload the list.
        ref.read(selectedShopIdProvider.notifier).state = shop.id;
        ref.invalidate(myShopsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop created')),
        );
        Navigator.of(context).pop();
      } else {
        // The gate reloads the store and switches to the dashboard.
        ref.invalidate(myShopsProvider);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    context.go('/home');
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _emailRule(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _phoneRule(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'This field is required';
    return RegExp(r'^\d{10}$').hasMatch(s)
        ? null
        : 'Enter a valid 10-digit phone number';
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _field(
    TextEditingController c,
    String label,
    String? Function(String?) validator, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _decoration(label),
      ),
    );
  }

  Widget _categoryField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: _category,
        decoration: _decoration('Category'),
        items: kStoreCategories
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(storeCategoryLabel(c)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _category = v),
        validator: (v) => v == null ? 'Select a category' : null,
      ),
    );
  }

  Widget _logoPicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _saving ? null : _pickLogo,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                backgroundImage: _logo == null ? null : FileImage(_logo!),
                child: _logo == null
                    ? const Icon(Icons.storefront_outlined, size: 36)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Store logo (optional)',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: widget.isAdditional,
        title: Text(
          widget.isAdditional ? 'Create new shop' : 'Set up your store',
          style: const TextStyle(
            fontFamily: AppFonts.brand,
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: widget.isAdditional
            ? null
            : [
                TextButton(
                  onPressed: _saving ? null : _logout,
                  child: const Text(
                    'Log out',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: _logoPicker()),
            const SizedBox(height: 20),
            Text(
              widget.isAdditional
                  ? 'Add another store to your account. You can edit these details later in the Store tab.'
                  : 'Create your store to start selling. You can edit these details later in the Store tab.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_name, 'Store name', _required),
                  _categoryField(),
                  _field(_email, 'Contact email', _emailRule,
                      keyboardType: TextInputType.emailAddress),
                  _field(_phone, 'Contact phone', _phoneRule,
                      keyboardType: TextInputType.phone),
                  _field(_address, 'Store address', _required, maxLines: 2),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create store',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}