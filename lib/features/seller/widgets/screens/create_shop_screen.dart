import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/shop/services/shop_api_service.dart';

class CreateShopScreen extends ConsumerStatefulWidget {
  const CreateShopScreen({super.key});

  @override
  ConsumerState<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends ConsumerState<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _returnPolicy = TextEditingController();
  final _address = TextEditingController();
  late final TextEditingController _email =
      TextEditingController(text: AuthState.instance.user?.email ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: AuthState.instance.user?.phone ?? '');
  File? _logo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefillFromSignup();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _description.dispose();
    _returnPolicy.dispose();
    super.dispose();
  }

  /// Pre-fill address / phone with what the owner entered at signup.
  Future<void> _prefillFromSignup() async {
    try {
      final me = await ref.read(shopApiServiceProvider).getMe();
      if (!mounted) return;
      if (_address.text.isEmpty) _address.text = signupAddress(me);
      if (_phone.text.isEmpty) _phone.text = me['phone']?.toString() ?? '';
    } catch (_) {
      // Fields stay empty; the owner can type them.
    }
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
        contactEmail: _email.text.trim(),
        description: _description.text.trim(),
        returnPolicy: _returnPolicy.text.trim(),
        address: _address.text.trim(),
        contactPhone: _phone.text.trim(),
      );

      // Optional logo: upload it, then save its URL on the new shop.
      if (_logo != null) {
        try {
          final url = await api.uploadShopImage(_logo!);
          await api.updateMyShop(
            name: shop.name,
            contactEmail: shop.contactEmail,
            description: shop.description,
            returnPolicy: shop.returnPolicy,
            address: shop.address,
            contactPhone: shop.contactPhone,
            image: url,
          );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Shop created, but the logo could not be uploaded. '
                  'You can add it later in the Store tab.',
                ),
              ),
            );
          }
        }
      }

      // The gate reloads the shop and switches to the dashboard.
      ref.invalidate(myShopProvider);
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
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
          'Shop logo (optional)',
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Set up your shop',
          style: TextStyle(
            fontFamily: AppFonts.brand,
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _logout,
            child: const Text('Log out', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: _logoPicker()),
            const SizedBox(height: 20),
            const Text(
              'Create your shop to start selling. You can edit these details later in the Store tab.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_name, 'Shop name', _required),
                  _field(_email, 'Contact email', _emailRule,
                      keyboardType: TextInputType.emailAddress),
                  _field(_phone, 'Contact phone', _required,
                      keyboardType: TextInputType.phone),
                  _field(_address, 'Pickup address', _required, maxLines: 2),
                  _field(_description, 'Description', _required, maxLines: 3),
                  _field(_returnPolicy, 'Return policy', _required, maxLines: 3),
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
                        'Create shop',
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