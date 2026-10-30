// features/seller/widgets/screens/product_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/product_form_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_brands_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_categories_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_inventory_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_products_provider.dart';

// ---- helpers for this form ---------------------------------------------

/// 149.99 stays 149.99, 150.0 shows as 150, null shows as empty.
String fmtNum(double? v) {
  if (v == null) return '';
  return v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toString();
}

String? optStr(TextEditingController c) {
  final t = c.text.trim();
  return t.isEmpty ? null : t;
}

double? optNum(TextEditingController c) {
  final t = c.text.trim();
  return t.isEmpty ? null : double.tryParse(t);
}

/// null when empty or valid, otherwise an error message.
String? numError(TextEditingController c, String label) {
  final t = c.text.trim();
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null || v < 0) return '$label must be a valid number';
  return null;
}

String shortError(Object e) => e.toString().replaceFirst('Exception: ', '');

/// All the fields of one variant row.
class VariantRow {
  VariantRow({this.id});

  factory VariantRow.fromVariant(SellerVariant v) {
    final r = VariantRow(id: v.id);
    r.name.text = v.name;
    r.size.text = v.size;
    for (final c in v.colorCodes) {
      final hex = normalizeHex(c) ?? c;
      if (!r.colorCodes.contains(hex)) r.colorCodes.add(hex);
    }
    r.price.text = fmtNum(v.sellingPrice);
    r.crossed.text = fmtNum(v.crossedPrice);
    r.cost.text = fmtNum(v.costPrice);
    r.qty.text = '${v.quantity}';
    r.weight.text = fmtNum(v.weight);
    r.sku.text = v.sku ?? '';
    r.hs.text = v.hsCode ?? '';
    r.barcode.text = v.altBarcode ?? '';
    r.images.addAll(v.imageUrls.map(ProductImageEntry.remote));
    return r;
  }

  final String? id; // null = new variant, not saved yet
  final name = TextEditingController();
  final size = TextEditingController();
  final List<String> colorCodes = []; // hex codes, for example #ff0000
  final price = TextEditingController();
  final crossed = TextEditingController();
  final cost = TextEditingController();
  final qty = TextEditingController();
  final weight = TextEditingController();
  final sku = TextEditingController();
  final hs = TextEditingController();
  final barcode = TextEditingController();

  /// Uploaded URLs and new files of this variant's images.
  final List<ProductImageEntry> images = [];

  void dispose() {
    for (final c in [
      name, size, price, crossed, cost, qty, weight, sku, hs, barcode,
    ]) {
      c.dispose();
    }
  }
}

// ----------------------------------------------------------------- screen

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

  // text fields
  final _name = TextEditingController();
  final _shortDesc = TextEditingController();
  final _longDesc = TextEditingController();
  final _price = TextEditingController();
  final _crossed = TextEditingController();
  final _cost = TextEditingController();
  final _qty = TextEditingController();
  final _weight = TextEditingController();
  final _sku = TextEditingController();
  final _hs = TextEditingController();
  final _barcode = TextEditingController();
  final _tags = TextEditingController();
  final _seoTitle = TextEditingController();
  final _seoDesc = TextEditingController();

  // dropdown values
  final _brandNotifier = ValueNotifier<String?>(null);
  final _categoryNotifier = ValueNotifier<List<String>>([]);
  final _audienceNotifier =
      ValueNotifier<ProductAudience?>(ProductAudience.unisex);

  /// Outlet that receives the opening stock of a NEW product.
  /// null = not chosen, the backend uses the main outlet.
  final _outletNotifier = ValueNotifier<String?>(null);

  // other state
  ProductStatus _status = ProductStatus.active;
  bool _isAvailable = true;
  DateTime? _releaseDate;
  List<String> _similarIds = [];
  List<ProductImageEntry> _images = [];
  File? _seoPicked;
  String? _seoUrl;
  final List<VariantRow> _variants = [];

  bool _saving = false;

  /// The full product from GET /products/:id (the list has no descriptions).
  SellerProduct? _base;
  bool _loadingDetails = false;
  bool _detailsFailed = false;

  final FocusNode _shortFocus = FocusNode();
  final FocusNode _longFocus = FocusNode();
  final GlobalKey _shortKey = GlobalKey();
  final GlobalKey _longKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  bool get _isEditing => widget.initial != null;
  bool get _canSave => !_saving && !_loadingDetails && !_detailsFailed;

  @override
  void initState() {
    super.initState();
    _scrollOnFocus(_shortFocus, _shortKey);
    _scrollOnFocus(_longFocus, _longKey);

    // When editing, load the full product first: the list does not contain
    // descriptions, tags, SEO and so on, so saving without it would erase them.
    if (_isEditing) {
      _loadingDetails = true;
      _fetchDetails();
    }
  }

  void _scrollOnFocus(FocusNode node, GlobalKey key) {
    node.addListener(() {
      if (!node.hasFocus) return;
      // Wait for the keyboard animation so the insets have settled.
      Future.delayed(const Duration(milliseconds: 260), () {
        final ctx = key.currentContext;
        if (ctx != null && mounted) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: 0.1,
          );
        }
      });
    });
  }

  Future<void> _fetchDetails() async {
    try {
      final full = await ref
          .read(sellerProductApiProvider)
          .getProduct(widget.initial!.id);
      if (!mounted) return;
      setState(() {
        _base = full;
        _applyProduct(full);
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

  /// Fills every field from a loaded product (call inside setState).
  void _applyProduct(SellerProduct p) {
    _name.text = p.name;
    _shortDesc.text = p.productDescription;
    _longDesc.text = p.longDescription;
    _price.text = p.hasVariants ? '' : fmtNum(p.sellingPrice);
    _crossed.text = fmtNum(p.crossedPrice);
    _cost.text = fmtNum(p.costPrice);
    _qty.text = p.hasVariants ? '' : '${p.quantity}';
    _weight.text = fmtNum(p.weight);
    _sku.text = p.sku ?? '';
    _hs.text = p.hsCode ?? '';
    _barcode.text = p.altBarcode ?? '';
    _tags.text = p.tags.join(', ');
    _seoTitle.text = p.seoTitle ?? '';
    _seoDesc.text = p.seoDescription ?? '';

    _brandNotifier.value = p.brandId;
    _categoryNotifier.value = [...p.categoryIds];
    _audienceNotifier.value = p.audience;
    _status = p.status;
    _isAvailable = p.isAvailable;
    _releaseDate = p.releaseDate;
    _similarIds = [...p.similarProductIds];
    _images = [for (final u in p.imageUrls) ProductImageEntry.remote(u)];
    _seoUrl = p.seoImage;
    _seoPicked = null;

    for (final v in _variants) {
      v.dispose();
    }
    _variants
      ..clear()
      ..addAll(p.variants.map(VariantRow.fromVariant));
  }

  @override
  void dispose() {
    for (final c in [
      _name, _shortDesc, _longDesc, _price, _crossed, _cost, _qty, _weight,
      _sku, _hs, _barcode, _tags, _seoTitle, _seoDesc,
    ]) {
      c.dispose();
    }
    for (final v in _variants) {
      v.dispose();
    }
    _brandNotifier.dispose();
    _categoryNotifier.dispose();
    _audienceNotifier.dispose();
    _outletNotifier.dispose();
    _shortFocus.dispose();
    _longFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- pickers

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _images.addAll(picked.map((x) => ProductImageEntry.local(File(x.path))));
    });
  }

  Future<void> _pickVariantImages(VariantRow row) async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      row.images.addAll(picked.map((x) => ProductImageEntry.local(File(x.path))));
    });
  }

  Future<void> _pickSeoImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _seoPicked = File(picked.path));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _releaseDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null
          ? DateTime(current.year, current.month, current.day)
          : now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() {
        _releaseDate = DateTime.utc(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickSimilar(List<SellerProduct> candidates) async {
    final result = await showSimilarProductsSheet(
      context,
      candidates: candidates,
      selected: _similarIds,
    );
    if (result != null && mounted) setState(() => _similarIds = result);
  }

  void _addVariant() => setState(() => _variants.add(VariantRow()));

  /// Removes a variant. A saved variant is deleted on the server when the
  /// product is saved, because the saved list no longer contains it.
  Future<void> _removeVariant(VariantRow row) async {
    if (!_variants.contains(row)) return;

    // Without any variant the product would switch to a plain product with
    // no variant prices, so at least one variant has to stay.
    final hadVariants = _isEditing && (_base?.variants.isNotEmpty ?? false);
    if (hadVariants && _variants.length == 1) {
      _showError('A product with variants needs at least one variant');
      return;
    }

    if (row.id != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete variant'),
          content: const Text(
            'This variant is deleted from the product when you tap Save changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    final i = _variants.indexOf(row);
    if (i < 0) return; // already removed, ignore the extra tap
    setState(() => _variants.removeAt(i).dispose());
  }

  void _showError(String message) => AppToast.error(context, message);

  // ------------------------------------------------------ collect + validate

  SellerProduct? _collect() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _showError('Enter a product name');
      return null;
    }
    final brandId = _brandNotifier.value;
    if (brandId == null) {
      _showError('Choose a brand');
      return null;
    }
    final categoryIds = _categoryNotifier.value;
    if (categoryIds.isEmpty) {
      _showError('Choose at least one category');
      return null;
    }
    final shortDesc = _shortDesc.text.trim();
    if (shortDesc.isEmpty) {
      _showError('Enter a short description');
      return null;
    }

    // variants
    final variants = <SellerVariant>[];
    final seenSkus = <String>{};
    for (var i = 0; i < _variants.length; i++) {
      final r = _variants[i];
      final label = 'Variant ${i + 1}';
      final vName = r.name.text.trim();
      final size = r.size.text.trim();
      final price = double.tryParse(r.price.text.trim());
      final qty = int.tryParse(r.qty.text.trim());

      if (vName.isEmpty || size.isEmpty) {
        _showError('$label needs a name and a size');
        return null;
      }
      if (!_sizeRule.hasMatch(size)) {
        _showError(
          '$label: size "$size" is not allowed. Use only letters, numbers, spaces and - . /',
        );
        return null;
      }
      if (price == null || price <= 0) {
        _showError('$label needs a valid selling price');
        return null;
      }
      // Quantity is only asked when a NEW product is created. A saved
      // product's stock is changed from Inventory > Stock in.
      if (!_isEditing && (qty == null || qty < 0)) {
        _showError('$label needs a valid quantity');
        return null;
      }
      final problem = numError(r.crossed, '$label crossed price') ??
          numError(r.cost, '$label cost price') ??
          numError(r.weight, '$label weight');
      if (problem != null) {
        _showError(problem);
        return null;
      }
      final crossed = optNum(r.crossed);
      if (crossed != null && crossed <= price) {
        _showError('$label: crossed price must be higher than the selling price');
        return null;
      }

      final sku = optStr(r.sku);
      if (sku != null && !seenSkus.add(sku.toLowerCase())) {
        _showError('SKU "$sku" is used twice. Each SKU must be unique');
        return null;
      }

      variants.add(
        SellerVariant(
          id: r.id,
          name: vName,
          size: size,
          colorCodes: [...r.colorCodes],
          sellingPrice: price,
          crossedPrice: crossed,
          costPrice: optNum(r.cost),
          quantity: qty ?? 0,
          weight: optNum(r.weight),
          sku: sku,
          hsCode: optStr(r.hs),
          altBarcode: optStr(r.barcode),
          // Images already uploaded. New files are uploaded on save.
          imageUrls: [
            for (final e in r.images)
              if (e.url != null) e.url!,
          ],
        ),
      );
    }

    // product-level price and stock (only when there are no variants)
    var sellingPrice = 0.0;
    var quantity = 0;
    double? crossedPrice, costPrice, weight;
    String? sku, hsCode, altBarcode;

    if (variants.isEmpty) {
      final price = double.tryParse(_price.text.trim());
      if (price == null || price <= 0) {
        _showError('Enter a valid selling price');
        return null;
      }

      int? qty;
      if (_isEditing) {
        // Not editable here: stock is changed from Inventory > Stock in.
        qty = _base?.quantity ?? 0;
      } else {
        qty = int.tryParse(_qty.text.trim());
        if (qty == null || qty < 0) {
          _showError('Enter a valid quantity');
          return null;
        }
      }

      final problem = numError(_crossed, 'Crossed price') ??
          numError(_cost, 'Cost price') ??
          numError(_weight, 'Weight');
      if (problem != null) {
        _showError(problem);
        return null;
      }
      crossedPrice = optNum(_crossed);
      if (crossedPrice != null && crossedPrice <= price) {
        _showError('Crossed price must be higher than the selling price');
        return null;
      }
      sellingPrice = price;
      quantity = qty;
      costPrice = optNum(_cost);
      weight = optNum(_weight);
      sku = optStr(_sku);
      hsCode = optStr(_hs);
      altBarcode = optStr(_barcode);
    }

    final tags = <String>[];
    for (final t in _tags.text.split(',')) {
      final tag = t.trim();
      if (tag.isNotEmpty && !tags.contains(tag)) tags.add(tag);
    }

    return SellerProduct(
      id: _base?.id ?? '',
      name: name,
      slug: _base?.slug ?? '',
      channel: _base?.channel ?? 'ALL',
      audience: _audienceNotifier.value ?? ProductAudience.unisex,
      status: _status,
      isAvailable: _isAvailable,
      hasVariants: variants.isNotEmpty,
      // Only a new product has a stock location. Empty = main outlet.
      outletId: _isEditing ? null : _outletNotifier.value,
      brandId: brandId,
      categoryIds: [...categoryIds],
      productDescription: shortDesc,
      longDescription: _longDesc.text.trim(),
      tags: tags,
      similarProductIds: [..._similarIds],
      releaseDate: _releaseDate,
      sellingPrice: sellingPrice,
      crossedPrice: crossedPrice,
      costPrice: costPrice,
      quantity: quantity,
      weight: weight,
      sku: sku,
      hsCode: hsCode,
      altBarcode: altBarcode,
      seoTitle: optStr(_seoTitle),
      seoDescription: optStr(_seoDesc),
      seoImage: _seoUrl,
      variants: variants,
    );
  }

  Future<void> _submit() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();

    final product = _collect();
    if (product == null) return;

    // The images of each variant, by the variant's position.
    final variantImages = <int, List<ProductImageEntry>>{
      for (var i = 0; i < _variants.length; i++) i: [..._variants[i].images],
    };

    final notifier = ref.read(sellerProductsProvider.notifier);
    setState(() => _saving = true);

    final result = _isEditing
        ? await notifier.updateProduct(
            _base!,
            product,
            images: _images,
            variantImages: variantImages,
            seoImage: _seoPicked,
          )
        : await notifier.addProduct(
            product,
            images: _images,
            variantImages: variantImages,
            seoImage: _seoPicked,
          );
    if (!mounted) return;

    if (!result.saved) {
      setState(() => _saving = false);
      _showError(result.message ?? 'Could not save the product');
      return;
    }

    // New products and new variants must appear in Inventory and in the
    // Stock in product picker, and deleted variants must disappear.
    ref.invalidate(allStockItemsProvider);
    ref.invalidate(sellerStockProvider);

    AppToast.success(
      context,
      result.message ??
          (_isEditing
              ? 'Product updated successfully'
              : 'Product published successfully'),
    );
    Navigator.of(context).pop();
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: kPageBg,
      // The bottom bar is lifted by hand so it sits right above the keyboard.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: kPageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Product' : 'Create Product',
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: AbsorbPointer(
                absorbing: _loadingDetails || _saving,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loadingDetails)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            color: AppColors.ink,
                            backgroundColor: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    if (_detailsFailed) _detailsFailedBanner(),
                    _mediaCard(),
                    _basicCard(),
                    _organizationCard(),
                    if (!_isEditing) _stockLocationCard(),
                    if (_variants.isEmpty) _priceCard(),
                    _variantsCard(),
                    CollapsibleCard(
                      icon: Iconsax.tag,
                      title: 'Tags, release and similar products',
                      subtitle: 'Optional',
                      child: _extrasBody(),
                    ),
                    CollapsibleCard(
                      icon: Icons.search,
                      title: 'SEO',
                      subtitle: 'Optional',
                      child: _seoBody(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + (bottomInset > 0 ? bottomInset : safeBottom),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                            _isEditing ? 'Save changes' : 'Add Product',
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
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ cards

  Widget _detailsFailedBanner() => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            TextButton(onPressed: _retryDetails, child: const Text('Retry')),
          ],
        ),
      );

  /// Shown instead of the quantity field when a saved product is edited.
  Widget _stockNote() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kPageBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Iconsax.info_circle, size: 18, color: AppColors.textGray),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Stock is added from Inventory > Stock in.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textGray),
              ),
            ),
          ],
        ),
      );

  Widget _mediaCard() {
    return SectionCard(
      icon: Iconsax.gallery_add,
      title: 'Media',
      trailing: _images.isEmpty
          ? null
          : TextButton(
              onPressed: _saving ? null : _pickImages,
              child: const Text('Add more'),
            ),
      child: _images.isEmpty
          ? AddMediaRow(onTap: _saving ? null : _pickImages)
          : ProductImagesRow(
              images: _images,
              enabled: !_saving,
              onAdd: _pickImages,
              onRemove: (i) => setState(() => _images.removeAt(i)),
            ),
    );
  }

  Widget _basicCard() {
    return SectionCard(
      icon: Iconsax.info_circle,
      title: 'Basic information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Product title', _name,
              hint: 'Enter product title',
              required: true,
              caps: TextCapitalization.words),
          const SizedBox(height: 16),
          _label('Status'),
          Row(
            children: [
              for (var i = 0; i < ProductStatus.values.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: ChoiceBox(
                    label: ProductStatus.values[i].label,
                    selected: ProductStatus.values[i] == _status,
                    onTap: () =>
                        setState(() => _status = ProductStatus.values[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isAvailable,
            activeColor: AppColors.ink,
            onChanged: (v) => setState(() => _isAvailable = v),
            title: const Text(
              'Available to customers',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          _field(
            'Short description',
            _shortDesc,
            hint: 'Write a short description',
            required: true,
            minLines: 3,
            maxLines: 4,
            focusNode: _shortFocus,
            fieldKey: _shortKey,
            caps: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          _field(
            'Long description',
            _longDesc,
            hint: 'Describe the product for your buyers (optional)',
            minLines: 4,
            maxLines: 6,
            focusNode: _longFocus,
            fieldKey: _longKey,
            caps: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _organizationCard() {
    return SectionCard(
      icon: Iconsax.category,
      title: 'Organization',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Brand', required: true),
          _brandField(),
          const SizedBox(height: 16),
          _label('Categories', required: true),
          _categoryField(),
          const SizedBox(height: 16),
          _label('Audience'),
          FormDropdown<ProductAudience>(
            notifier: _audienceNotifier,
            hint: 'Select audience',
            items: [
              for (final a in ProductAudience.values)
                DropdownItem<ProductAudience>(
                  value: a,
                  height: 44,
                  child: formItemText(a.label),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Which outlet receives the opening stock of a new product.
  Widget _stockLocationCard() {
    return SectionCard(
      icon: Iconsax.location,
      title: 'Stock location',
      subtitle: 'Optional. The opening stock goes to this outlet.',
      child: _outletField(),
    );
  }

  Widget _priceCard() {
    return SectionCard(
      icon: Icons.payments_outlined,
      title: 'Price and stock',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pair(
            _field('Selling price', _price,
                hint: '0', required: true, decimal: true),
            _field('Cost per item', _cost, hint: 'Optional', decimal: true),
          ),
          const SizedBox(height: 16),
          if (_isEditing) ...[
            _field('Crossed price', _crossed, hint: 'Optional', decimal: true),
            const SizedBox(height: 14),
            _stockNote(),
          ] else
            _pair(
              _field('Crossed price', _crossed,
                  hint: 'Optional', decimal: true),
              _field('Quantity', _qty,
                  hint: '0', required: true, integer: true),
            ),
          const SizedBox(height: 14),
          _marginTiles(),
          const SizedBox(height: 6),
          CollapsibleCard(
            plain: true,
            title: 'More details',
            subtitle: 'Optional',
            child: Column(
              children: [
                _pair(
                  _field('Weight (kg)', _weight,
                      hint: 'Optional', decimal: true),
                  _field('SKU', _sku,
                      hint: 'Optional', caps: TextCapitalization.characters),
                ),
                const SizedBox(height: 16),
                _pair(
                  _field('HS code', _hs, hint: 'Optional'),
                  _field('Barcode', _barcode, hint: 'Optional'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _marginTiles() {
    return ListenableBuilder(
      listenable: Listenable.merge([_price, _cost]),
      builder: (context, _) {
        final price = double.tryParse(_price.text.trim());
        final cost = double.tryParse(_cost.text.trim());
        var profit = '-';
        var margin = '-';
        if (price != null && price > 0 && cost != null) {
          final p = price - cost;
          profit = formatPrice(p);
          margin = '${(p / price * 100).toStringAsFixed(1)}%';
        }
        return _pair(
          MetricTile(label: 'Margin', value: margin),
          MetricTile(label: 'Profit', value: profit),
        );
      },
    );
  }

  Widget _variantsCard() {
    return SectionCard(
      icon: Icons.layers_outlined,
      title: 'Variants',
      subtitle: _isEditing
          ? 'Each variant has its own price and images. Stock is added from Inventory > Stock in. A variant you remove here is deleted when you save.'
          : 'Optional. Each variant has its own price, stock and images.',
      trailing: TextButton.icon(
        onPressed: _saving ? null : _addVariant,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add'),
      ),
      child: _variants.isEmpty
          ? const Text(
              'No variants. Add one if this product comes in different sizes or colours.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textGray),
            )
          : Column(
              children: [
                for (var i = 0; i < _variants.length; i++) _variantCard(i),
              ],
            ),
    );
  }

  Widget _variantCard(int index) {
    final r = _variants[index];
    final saved = r.id != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPageBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isEditing && !saved
                      ? 'Variant ${index + 1} (new)'
                      : 'Variant ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _saving ? null : () => _removeVariant(r),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                tooltip: 'Remove variant',
              ),
            ],
          ),
          _field('Name', r.name,
              hint: 'Variant name',
              required: true,
              caps: TextCapitalization.words),
          const SizedBox(height: 14),
          _field('Size', r.size, hint: 'Size', required: true),
          const SizedBox(height: 14),
          _label('Colours'),
          VariantColorPicker(
            selected: r.colorCodes,
            onChanged: (v) => setState(() {
              r.colorCodes
                ..clear()
                ..addAll(v);
            }),
          ),
          const SizedBox(height: 14),
          _label('Images (optional)'),
          r.images.isEmpty
              ? AddMediaRow(
                  onTap: _saving ? null : () => _pickVariantImages(r),
                )
              : ProductImagesRow(
                  images: r.images,
                  enabled: !_saving,
                  onAdd: () => _pickVariantImages(r),
                  onRemove: (i) => setState(() => r.images.removeAt(i)),
                ),
          const SizedBox(height: 14),
          if (_isEditing)
            _field('Selling price', r.price,
                hint: '0', required: true, decimal: true)
          else
            _pair(
              _field('Selling price', r.price,
                  hint: '0', required: true, decimal: true),
              _field('Quantity', r.qty,
                  hint: '0', required: true, integer: true),
            ),
          CollapsibleCard(
            plain: true,
            title: 'More details',
            subtitle: 'Optional',
            child: Column(
              children: [
                _pair(
                  _field('Crossed price', r.crossed,
                      hint: 'Optional', decimal: true),
                  _field('Cost price', r.cost, hint: 'Optional', decimal: true),
                ),
                const SizedBox(height: 14),
                _pair(
                  _field('Weight (kg)', r.weight,
                      hint: 'Optional', decimal: true),
                  _field('SKU', r.sku,
                      hint: 'Optional', caps: TextCapitalization.characters),
                ),
                const SizedBox(height: 14),
                _pair(
                  _field('HS code', r.hs, hint: 'Optional'),
                  _field('Barcode', r.barcode, hint: 'Optional'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _extrasBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('Tags', _tags, hint: 'Separate tags with commas'),
        const SizedBox(height: 16),
        _label('Release date'),
        ReleaseDateField(
          date: _releaseDate,
          onTap: _pickDate,
          onClear: () => setState(() => _releaseDate = null),
        ),
        const SizedBox(height: 16),
        _label('Similar products'),
        _similarField(),
      ],
    );
  }

  Widget _seoBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('SEO title', _seoTitle, hint: 'Shown in search results'),
        const SizedBox(height: 16),
        _field('SEO description', _seoDesc,
            hint: 'Short summary for search engines', minLines: 2, maxLines: 3),
        const SizedBox(height: 16),
        _label('SEO image (optional)'),
        SeoImageTile(
          picked: _seoPicked,
          url: _seoUrl,
          enabled: !_saving,
          onTap: _pickSeoImage,
        ),
      ],
    );
  }

  // -------------------------------------------------------------- dropdowns

  Widget _brandField() {
    final async = ref.watch(sellerBrandsProvider);
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const FormDisabledField('Loading brands...', loading: true),
      error: (e, _) => FormErrorField(
        'Could not load brands: ${shortError(e)}',
        () => ref.invalidate(sellerBrandsProvider),
      ),
      data: (brands) {
        if (brands.isEmpty) {
          return const FormDisabledField('No brands yet. Create one from the Brands page.');
        }
        final items = <DropdownItem<String>>[
          for (final b in brands)
            DropdownItem<String>(value: b.id, height: 44, child: formItemText(b.name)),
        ];
        // A product can point at a brand that is no longer in the list.
        final current = _brandNotifier.value;
        if (current != null && !brands.any((b) => b.id == current)) {
          items.add(
            DropdownItem<String>(
              value: current,
              height: 44,
              child: formItemText(_base?.brandName ?? 'Current brand'),
            ),
          );
        }
        return FormDropdown<String>(
          notifier: _brandNotifier,
          hint: 'Select brand',
          items: items,
        );
      },
    );
  }

  Widget _categoryField() {
    final async = ref.watch(sellerCategoriesProvider);
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const FormDisabledField('Loading categories...', loading: true),
      error: (e, _) => FormErrorField(
        'Could not load categories: ${shortError(e)}',
        () => ref.invalidate(sellerCategoriesProvider),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const FormDisabledField(
            'No categories yet. Create one from the Categories page.',
          );
        }
        final names = {for (final c in categories) c.id: c.name};
        for (final c in _base?.categories ?? const <SellerRef>[]) {
          names.putIfAbsent(c.id, () => c.name);
        }
        return CategoryMultiSelect(
          categories: categories,
          names: names,
          notifier: _categoryNotifier,
        );
      },
    );
  }

  Widget _outletField() {
    final async = ref.watch(sellerOutletsProvider);
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const FormDisabledField('Loading outlets...', loading: true),
      error: (e, _) => FormErrorField(
        'Could not load outlets: ${shortError(e)}',
        () => ref.invalidate(sellerOutletsProvider),
      ),
      data: (all) {
        final outlets = all.where((o) => o.isActive).toList();
        if (outlets.isEmpty) {
          return const FormDisabledField('No active outlet. The main outlet is used.');
        }
        return FormDropdown<String>(
          notifier: _outletNotifier,
          hint: 'Main outlet (default)',
          items: [
            for (final o in outlets)
              DropdownItem<String>(
                value: o.id,
                height: 44,
                child: formItemText(o.isMain ? '${o.name} (main)' : o.name),
              ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------- other fields

  Widget _similarField() {
    final all = ref.watch(sellerProductsProvider).value ?? const <SellerProduct>[];
    final byId = {for (final p in all) p.id: p};
    final selfId = _base?.id ?? '';
    final candidates = all.where((p) => p.id != selfId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_similarIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in _similarIds)
                  BlackChip(
                    label: byId[id]?.name ?? 'Product',
                    onRemove: () => setState(() => _similarIds.remove(id)),
                  ),
              ],
            ),
          ),
        OutlinedButton(
          onPressed: candidates.isEmpty ? null : () => _pickSimilar(candidates),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Choose products'),
        ),
      ],
    );
  }

  // ---------------------------------------------------- small building blocks

  /// Two fields side by side; stacked on very narrow screens.
  Widget _pair(Widget a, Widget b) => LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 300) {
            return Column(children: [a, const SizedBox(height: 14), b]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b),
            ],
          );
        },
      );

  Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(
          TextSpan(
            text: text,
            children: [
              if (required)
                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          style: TextStyle(
            fontSize: Responsive.font(context, 13),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool required = false,
    bool decimal = false,
    bool integer = false,
    int minLines = 1,
    int maxLines = 1,
    FocusNode? focusNode,
    Key? fieldKey,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required),
        TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          minLines: minLines,
          maxLines: maxLines,
          textCapitalization: caps,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : integer
                  ? TextInputType.number
                  : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
          textInputAction:
              maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          decoration: _decoration(hint),
        ),
      ],
    );
  }

  InputDecoration _decoration(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textGray),
        isDense: true,
        filled: true,
        fillColor: kFieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.2),
        ),
      );
}