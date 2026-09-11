// features/seller/screens/product_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_products_provider.dart';


class ProductFormScreen extends ConsumerStatefulWidget {
  final SellerProduct? initial;
  const ProductFormScreen({super.key, this.initial});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _optionLabel;
  late final TextEditingController _optionsText;
  late final TextEditingController _description;
  late String _category;
  late ProductStatus _status;
  File? _pickedImage;
  String? _existingImageUrl;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _stock = TextEditingController(text: p != null ? p.stock.toString() : '');
    _optionLabel = TextEditingController(text: p?.optionLabel ?? 'Size');
    _optionsText = TextEditingController(text: p?.options.join(', ') ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _category = p?.category ?? kSellerCategories.first;
    _status = p?.status ?? ProductStatus.active;
    _existingImageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _optionLabel.dispose();
    _optionsText.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _existingImageUrl = null;
    });
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;

    final options = _optionsText.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final notifier = ref.read(sellerProductsProvider.notifier);

    if (_isEditing) {
      final updated = widget.initial!.copyWith(
        name: _name.text.trim(),
        price: double.tryParse(_price.text) ?? 0,
        stock: int.tryParse(_stock.text) ?? 0,
        category: _category,
        status: _status,
        description: _description.text.trim(),
        optionLabel: _optionLabel.text.trim(),
        options: options,
        imageUrl: _pickedImage?.path ?? _existingImageUrl ?? '',
      );
      notifier.updateProduct(updated);
    } else {
      final draft = SellerProduct(
        id: notifier.newId(),
        name: _name.text.trim(),
        price: double.tryParse(_price.text) ?? 0,
        category: _category,
        imageUrl: _pickedImage?.path ?? '',
        stock: int.tryParse(_stock.text) ?? 0,
        status: _status,
        description: _description.text.trim(),
        optionLabel: _optionLabel.text.trim(),
        options: options,
      );
      notifier.addProduct(draft);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _pickedImage != null || (_existingImageUrl?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
        title: Text(_isEditing ? 'Edit product' : 'Add new product',
            style: const TextStyle(fontFamily: AppFonts.brand, fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product image', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _pickedImage != null
                              ? Image.file(_pickedImage!, fit: BoxFit.cover)
                              : Image.network(_existingImageUrl!, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200)),
                          Positioned(
                            left: 0, right: 0, bottom: 0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _pickImage,
                                    child: Container(
                                      color: Colors.black.withOpacity(0.55),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: const Text('Replace', textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: _removeImage,
                                  child: Container(
                                    width: 44,
                                    color: Colors.black.withOpacity(0.55),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(backgroundColor: AppColors.ink, radius: 22, child: const Icon(Icons.add, color: Colors.white)),
                          const SizedBox(height: 8),
                          const Text('Upload photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Tap to choose from your device', textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _label('Product name'),
            TextField(controller: _name, decoration: _inputDecoration('e.g. Silk Slip Dress')),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Price (\$)'),
                    TextField(controller: _price, keyboardType: TextInputType.number, decoration: _inputDecoration('0')),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Stock'),
                    TextField(controller: _stock, keyboardType: TextInputType.number, decoration: _inputDecoration('0')),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Category'),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: _inputDecoration(null),
                      items: kSellerCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Status'),
                    DropdownButtonFormField<ProductStatus>(
                      initialValue: _status,
                      decoration: _inputDecoration(null),
                      items: ProductStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Variant label'),
                    TextField(controller: _optionLabel, decoration: _inputDecoration('Size / Colour / Shade')),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Variants'),
                    TextField(controller: _optionsText, decoration: _inputDecoration('S, M, L')),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _label('Description'),
            TextField(
              controller: _description,
              maxLines: 4,
              decoration: _inputDecoration('Describe the product for your buyers...'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(_isEditing ? 'Save changes' : 'Publish product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  InputDecoration _inputDecoration(String? hint) => InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.ink)),
      );
}