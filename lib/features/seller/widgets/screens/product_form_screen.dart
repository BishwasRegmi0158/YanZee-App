// features/seller/screens/product_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
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

  final FocusNode _descriptionFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _descriptionKey = GlobalKey();

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(0) : '',
    );
    _stock = TextEditingController(text: p != null ? p.stock.toString() : '');
    _optionLabel = TextEditingController(text: p?.optionLabel ?? 'Size');
    _optionsText = TextEditingController(text: p?.options.join(', ') ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _category = p?.category ?? kSellerCategories.first;
    _status = p?.status ?? ProductStatus.active;
    _existingImageUrl = p?.imageUrl;

    _descriptionFocus.addListener(() {
      if (_descriptionFocus.hasFocus) {
        // Give the keyboard animation time to finish so viewInsets.bottom
        // has settled to its final value before we scroll — one frame
        // isn't enough since resizeToAvoidBottomInset is off now and the
        // keyboard animates in over ~250ms.
        Future.delayed(const Duration(milliseconds: 260), () {
          final ctx = _descriptionKey.currentContext;
          if (ctx != null && mounted) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: 0.0,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _optionLabel.dispose();
    _optionsText.dispose();
    _description.dispose();
    _descriptionFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
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

    final options = _optionsText.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final imageSize = Responsive.isSmallPhone(context) ? 130.0 : 160.0;

    return Scaffold(
      backgroundColor: Colors.white,
      // Handling the inset manually below gives us reliable control over
      // exactly how much extra scroll room the description field gets —
      // resizeToAvoidBottomInset was zeroing out viewInsets.bottom inside
      // the body before our own padding ever saw it.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit product' : 'Add new product',
          style: TextStyle(
            fontFamily: AppFonts.brand,
            fontSize: Responsive.font(context, 18),
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              // bottomInset (keyboard height) + generous extra room so the
              // description field can always scroll clear above both the
              // keyboard and the bottom action bar, whichever field has
              // focus.
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset + 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product image',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                _pickedImage != null
                                    ? Image.file(_pickedImage!, fit: BoxFit.cover)
                                    : Image.network(
                                        _existingImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(color: Colors.grey.shade200),
                                      ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: _pickImage,
                                          child: Container(
                                            color: Colors.black.withOpacity(0.55),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Text(
                                              'Replace',
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: Responsive.font(
                                                  context,
                                                  12,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _removeImage,
                                        child: Container(
                                          width: 44,
                                          color: Colors.black.withOpacity(0.55),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
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
                                const CircleAvatar(
                                  backgroundColor: AppColors.ink,
                                  radius: 22,
                                  child: Icon(Icons.add, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload photo',
                                  style: TextStyle(
                                    fontSize: Responsive.font(context, 13),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Tap to choose from your device',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: Responsive.font(context, 11),
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _label(context, 'Product name'),
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('e.g. Silk Slip Dress'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Price (\$)'),
                            TextField(
                              controller: _price,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration('0'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Stock'),
                            TextField(
                              controller: _stock,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration('0'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Category'),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              isExpanded: true,
                              decoration: _inputDecoration(null),
                              items: kSellerCategories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Status'),
                            DropdownButtonFormField<ProductStatus>(
                              initialValue: _status,
                              isExpanded: true,
                              decoration: _inputDecoration(null),
                              items: ProductStatus.values
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Variant label'),
                            TextField(
                              controller: _optionLabel,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration('Size / Colour / Shade'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Variants'),
                            TextField(
                              controller: _optionsText,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration('S, M, L'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label(context, 'Description'),
                  TextField(
                    key: _descriptionKey,
                    controller: _description,
                    focusNode: _descriptionFocus,
                    maxLines: 4,
                    minLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: _inputDecoration(
                      'Describe the product for your buyers...',
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Bottom action bar is now a normal Column child instead of
          // bottomNavigationBar, so it doesn't fight with the keyboard —
          // it just sits below the scroll area and gets pushed up with
          // everything else via the SafeArea + viewInsets padding.
          SafeArea(
            top: false,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 100),
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isEditing ? 'Save changes' : 'Publish product',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: Responsive.font(context, 13),
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  InputDecoration _inputDecoration(String? hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.ink),
    ),
  );
}