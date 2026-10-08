import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/data/services/category_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

class CreateCategoryScreen extends ConsumerStatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  ConsumerState<CreateCategoryScreen> createState() =>
      _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends ConsumerState<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  File? _image;
  bool _isAvailable = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) setState(() => _image = File(picked.path));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null || storeId.isEmpty) {
      _snack('No store loaded.');
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(categoryApiServiceProvider);

      // 1) upload the image, 2) put its URL in the create request
      String? imageUrl;
      if (_image != null) {
        imageUrl = await api.uploadCategoryImage(storeId, _image!);
      }

      final description = _description.text.trim();
      await api.createCategory(
        storeId,
        name: _name.text.trim(),
        isAvailable: _isAvailable,
        image: imageUrl,
        description: description.isEmpty ? null : description,
      );

      if (!mounted) return;
      _snack('Category created');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _imagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _saving ? null : _pickImage,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            image: _image == null
                ? null
                : DecorationImage(image: FileImage(_image!), fit: BoxFit.cover),
          ),
          child: _image == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.gallery_add, size: 30),
                    const SizedBox(height: 6),
                    Text(
                      'Add image',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                )
              : null,
        ),
      ),
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
        title: const Text(
          'Create category',
          style: TextStyle(
            fontFamily: AppFonts.brand,
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _imagePicker(),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Category image (optional)',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: _decoration('Category name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'This field is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: _decoration('Description (optional)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isAvailable,
              activeThumbColor: Colors.black,
              onChanged: _saving ? null : (v) => setState(() => _isAvailable = v),
              title: const Text(
                'Available to customers',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
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
                        'Create category',
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