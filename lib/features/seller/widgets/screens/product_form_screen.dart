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

/// The three text fields of one variant row.
class _VariantRow {
  _VariantRow({String size = '', String stock = '', String sku = ''})
      : size = TextEditingController(text: size),
        stock = TextEditingController(text: stock),
        sku = TextEditingController(text: sku);

  final TextEditingController size;
  final TextEditingController stock;
  final TextEditingController sku;

  void dispose() {
    size.dispose();
    stock.dispose();
    sku.dispose();
  }
}

class ProductFormScreen extends ConsumerStatefulWidget {
  final SellerProduct? initial;
  const ProductFormScreen({super.key, this.initial});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  // Backend rule: a variant size may contain only letters, numbers,
  // spaces and the characters - . /
  static final _sizeRule = RegExp(r'^[A-Za-z0-9 \-./]+$');

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late final TextEditingController _description;
  late String _category;
  late ProductStatus _status;
  late ProductAudience _audience;
  final List<_VariantRow> _variants = [];
  File? _pickedImage;
  String? _existingImageUrl;
  bool _saving = false;

  /// The full product from GET /products/:id (the list has no description).
  SellerProduct? _base;
  bool _loadingDetails = false;
  bool _detailsFailed = false;

  final FocusNode _descriptionFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _descriptionKey = GlobalKey();

  bool get _isEditing => widget.initial != null;

  /// 149.99 stays 149.99, 150.0 shows as 150.
  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _base = p;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p != null ? _fmt(p.price) : '');
    _discount = TextEditingController(
      text: p?.discountPrice != null ? _fmt(p!.discountPrice!) : '',
    );
    _description = TextEditingController(text: p?.description ?? '');
    _category = (p != null && kSellerCategories.contains(p.category))
        ? p.category
        : kSellerCategories.first;
    _status = p?.status ?? ProductStatus.active;
    _audience = p?.audience ?? ProductAudience.unisex;
    _existingImageUrl = p?.imageUrl;

    if (p != null && p.variants.isNotEmpty) {
      for (final v in p.variants) {
        _variants.add(
          _VariantRow(size: v.size, stock: v.stock.toString(), sku: v.sku),
        );
      }
    } else {
      _variants.add(_VariantRow());
    }

    _descriptionFocus.addListener(() {
      if (_descriptionFocus.hasFocus) {
        // Give the keyboard animation time to finish so viewInsets.bottom
        // has settled to its final value before we scroll.
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

    // When editing, load the full product first. The list does not contain
    // the description, so saving without it would erase it on the server.
    if (_isEditing) {
      _loadingDetails = true;
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    try {
      final full = await ref
          .read(sellerProductApiProvider)
          .getProduct(widget.initial!.id);
      if (!mounted) return;
      setState(() {
        _base = full;
        if (_description.text.isEmpty) _description.text = full.description;
        _loadingDetails = false;
        _detailsFailed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDetails = false;
        _detailsFailed = true;
      });
    }
  }

  void _retryDetails() {
    setState(() {
      _loadingDetails = true;
      _detailsFailed = false;
    });
    _fetchDetails();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _discount.dispose();
    _description.dispose();
    for (final v in _variants) {
      v.dispose();
    }
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

  void _addVariant() => setState(() => _variants.add(_VariantRow()));

  void _removeVariant(int index) {
    if (_variants.length <= 1) return; // at least one variant is required
    setState(() => _variants.removeAt(index).dispose());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _canSave => !_saving && !_loadingDetails && !_detailsFailed;

  Future<void> _submit() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();

    final name = _name.text.trim();
    if (name.isEmpty) return _showError('Enter a product name');

    final price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) return _showError('Enter a valid price');

    double? discount;
    if (_discount.text.trim().isNotEmpty) {
      discount = double.tryParse(_discount.text.trim());
      if (discount == null || discount <= 0 || discount >= price) {
        return _showError('Discount price must be lower than the price');
      }
    }

    final variants = <SellerVariant>[];
    final seenSkus = <String>{};
    for (final row in _variants) {
      final size = row.size.text.trim();
      final sku = row.sku.text.trim();
      final stock = int.tryParse(row.stock.text.trim());
      if (size.isEmpty || sku.isEmpty || stock == null || stock < 0) {
        return _showError('Every variant needs a size, a stock number and a SKU');
      }
      if (!_sizeRule.hasMatch(size)) {
        return _showError(
          'Size "$size" is not allowed. Use only letters, numbers, spaces and - . /',
        );
      }
      if (!seenSkus.add(sku.toLowerCase())) {
        return _showError('SKU "$sku" is used twice. Each SKU must be unique');
      }
      variants.add(SellerVariant(size: size, stock: stock, sku: sku));
    }

    final notifier = ref.read(sellerProductsProvider.notifier);
    final description = _description.text.trim();

    final SellerProduct product;
    if (_isEditing) {
      product = _base!.copyWith(
        name: name,
        price: price,
        discountPrice: discount,
        clearDiscount: discount == null,
        category: _category,
        audience: _audience,
        status: _status,
        description: description,
        variants: variants,
        imageUrl: _existingImageUrl ?? '', // '' clears the image
      );
    } else {
      product = SellerProduct(
        id: '',
        name: name,
        price: price,
        discountPrice: discount,
        category: _category,
        audience: _audience,
        status: _status,
        description: description,
        variants: variants,
      );
    }

    setState(() => _saving = true);
    final error = _isEditing
        ? await notifier.updateProduct(product, image: _pickedImage)
        : await notifier.addProduct(product, image: _pickedImage);
    if (!mounted) return;

    if (error != null) {
      setState(() => _saving = false);
      _showError(error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Product updated' : 'Product published')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        _pickedImage != null || (_existingImageUrl?.isNotEmpty ?? false);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final imageSize = Responsive.isSmallPhone(context) ? 130.0 : 160.0;

    return Scaffold(
      backgroundColor: Colors.white,
      // Handling the inset manually below gives us reliable control over
      // exactly how much extra scroll room the fields get.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset + 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingDetails)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(
                        color: AppColors.ink,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  if (_detailsFailed)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Could not load the full product details, so saving is disabled.',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                          TextButton(
                            onPressed: _retryDetails,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  _label(context, 'Product image'),
                  GestureDetector(
                    onTap: _saving ? null : _pickImage,
                    child: Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
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
                                          onTap: _saving ? null : _pickImage,
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
                                                fontSize:
                                                    Responsive.font(context, 12),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _saving ? null : _removeImage,
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
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
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
                            _label(context, 'Discount price'),
                            TextField(
                              controller: _discount,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration('Optional'),
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
                            _label(context, 'Audience'),
                            DropdownButtonFormField<ProductAudience>(
                              initialValue: _audience,
                              isExpanded: true,
                              decoration: _inputDecoration(null),
                              items: ProductAudience.values
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a,
                                      child: Text(
                                        a.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _audience = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label(context, 'Status'),
                  DropdownButtonFormField<ProductStatus>(
                    initialValue: _status,
                    isExpanded: true,
                    decoration: _inputDecoration(null),
                    items: ProductStatus.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 24),
                  _label(context, 'Variants (size, stock and SKU)'),
                  for (var i = 0; i < _variants.length; i++) _variantCard(i),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _addVariant,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add variant'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
                        onPressed: _canSave ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
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

  /// One variant: size + stock on the first line, SKU + remove on the second.
  Widget _variantCard(int index) {
    final row = _variants[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.size,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Size (e.g. M, 500g)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: row.stock,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Stock'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.sku,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('SKU (e.g. JCK-LTHR-BLK-M)'),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed:
                    (_saving || _variants.length <= 1) ? null : () => _removeVariant(index),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                tooltip: 'Remove variant',
              ),
            ],
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
        isDense: true,
        filled: true,
        fillColor: Colors.white,
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