// features/seller/widgets/screens/product_details_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/product_form_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_products_provider.dart';
import 'package:yanzee_app/features/seller/widgets/screens/product_form_screen.dart';

/// Read-only view of one product. The list item is shown at once, then the
/// full product (descriptions, tags, variants, SEO) is loaded from the server.
class ProductDetailsScreen extends ConsumerStatefulWidget {
  final SellerProduct product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  late SellerProduct _p = widget.product;
  bool _loading = true;
  String? _error;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final full = await ref
          .read(sellerProductApiProvider)
          .getProduct(widget.product.id)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _p = full;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is TimeoutException
            ? 'The server took too long to respond'
            : e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(initial: _p)),
    );
    if (mounted) _load(); // show the changes the seller just saved
  }

  (Color bg, Color fg) _statusColors(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return (const Color(0xFFDDF5DD), const Color(0xFF1E8E3E));
      case ProductStatus.draft:
        return (Colors.grey.shade200, Colors.grey.shade700);
      case ProductStatus.archived:
        return (const Color(0xFFFDE9D3), const Color(0xFFC2540C));
    }
  }

  String _priceText() {
    if (_p.variants.isNotEmpty) {
      final prices = _p.variants.map((v) => v.sellingPrice).toList()..sort();
      final min = prices.first;
      final max = prices.last;
      return min == max
          ? formatPrice(min)
          : '${formatPrice(min)} - ${formatPrice(max)}';
    }
    final min = _p.priceMin;
    final max = _p.priceMax;
    if (_p.hasVariants && min != null && max != null && min != max) {
      return '${formatPrice(min)} - ${formatPrice(max)}';
    }
    return formatPrice(_p.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: kPageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Product details',
          style: TextStyle(
            fontFamily: AppFonts.brand,
            fontSize: Responsive.font(context, 18),
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (_loading)
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
          if (_error != null) _errorBanner(),
          _gallery(),
          const SizedBox(height: 14),
          _headerCard(),
          if (_p.productDescription.isNotEmpty || _p.longDescription.isNotEmpty)
            _descriptionCard(),
          _organizationCard(),
          if (_p.variants.isEmpty) _inventoryCard(),
          if (_p.variants.isNotEmpty) _variantsCard(),
          if (_p.tags.isNotEmpty || _p.releaseDate != null) _extrasCard(),
          if ((_p.seoTitle ?? '').isNotEmpty ||
              (_p.seoDescription ?? '').isNotEmpty)
            _seoCard(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _edit,
              icon: const Icon(Iconsax.edit_2, size: 18, color: Colors.white),
              label: const Text(
                'Edit product',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ parts

  Widget _errorBanner() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Could not load the full details: $_error',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: Colors.red.shade800),
              ),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );

  Widget _gallery() {
    final images = _p.imageUrls;
    final placeholder = Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Iconsax.gallery_slash, size: 40, color: AppColors.textGray),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: images.isEmpty
            ? placeholder
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => placeholder,
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_page + 1} / ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _headerCard() {
    final (bg, fg) = _statusColors(_p.status);
    final crossed = _p.crossedPrice;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill(_p.status.label, bg, fg),
              if (!_p.isAvailable)
                _pill('Hidden from customers', Colors.red.withOpacity(0.08),
                    Colors.red.shade700),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _p.name,
            style: TextStyle(
              fontSize: Responsive.font(context, 18),
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if ((_p.brandName ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _p.brandName!,
              style: const TextStyle(fontSize: 13, color: AppColors.textGray),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _priceText(),
                style: TextStyle(
                  fontSize: Responsive.font(context, 17),
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              if (_p.variants.isEmpty && crossed != null && crossed > _p.price)
                Text(
                  formatPrice(crossed),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _p.variants.isNotEmpty
                ? '${_p.stock} in stock across ${_p.variants.length} variant${_p.variants.length == 1 ? '' : 's'}'
                : (_p.hasVariants
                    ? '${_p.variantCount} variants'
                    : (_p.quantity == 0 ? 'No stock' : '${_p.quantity} in stock')),
            style: TextStyle(
              fontSize: 13,
              color: (!_p.hasVariants && _p.quantity == 0)
                  ? Colors.red.shade600
                  : AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionCard() {
    return SectionCard(
      icon: Iconsax.document_text,
      title: 'Description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_p.productDescription.isNotEmpty)
            Text(
              _p.productDescription,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          if (_p.productDescription.isNotEmpty && _p.longDescription.isNotEmpty)
            const SizedBox(height: 12),
          if (_p.longDescription.isNotEmpty)
            Text(
              _p.longDescription,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.textGray,
              ),
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
          _kv('Brand', _p.brandName),
          _kv('Audience', _p.audience.label),
          if (_p.categories.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Categories',
              style: TextStyle(fontSize: 13, color: AppColors.textGray),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _p.categories) BlackChip(label: c.name, onRemove: null),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _inventoryCard() {
    final cost = _p.costPrice;
    String? profit, margin;
    if (cost != null && _p.price > 0) {
      final p = _p.price - cost;
      profit = formatPrice(p);
      margin = '${(p / _p.price * 100).toStringAsFixed(1)}%';
    }
    return SectionCard(
      icon: Icons.payments_outlined,
      title: 'Price and stock',
      child: Column(
        children: [
          _kv('Selling price', formatPrice(_p.price)),
          _kv('Crossed price',
              _p.crossedPrice == null ? null : formatPrice(_p.crossedPrice!)),
          _kv('Cost per item', cost == null ? null : formatPrice(cost)),
          _kv('Profit', profit),
          _kv('Margin', margin),
          _kv('Quantity', '${_p.quantity}'),
          _kv('Weight', _p.weight == null ? null : '${_p.weight} kg'),
          _kv('SKU', _p.sku),
          _kv('HS code', _p.hsCode),
          _kv('Barcode', _p.altBarcode),
        ],
      ),
    );
  }

  Widget _variantsCard() {
    return SectionCard(
      icon: Icons.layers_outlined,
      title: 'Variants',
      subtitle: '${_p.variants.length} variant${_p.variants.length == 1 ? '' : 's'}',
      child: Column(
        children: [for (final v in _p.variants) _variantTile(v)],
      ),
    );
  }

  Widget _variantTile(SellerVariant v) {
    final crossed = v.crossedPrice;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPageBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (v.imageUrls.isNotEmpty) ...[
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final url in v.imageUrls)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  v.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                formatPrice(v.sellingPrice),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (crossed != null && crossed > v.sellingPrice) ...[
                const SizedBox(width: 6),
                Text(
                  formatPrice(crossed),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Size ${v.size}  •  ${v.quantity == 0 ? 'No stock' : '${v.quantity} in stock'}',
            style: TextStyle(
              fontSize: 12.5,
              color: v.quantity == 0 ? Colors.red.shade600 : AppColors.textGray,
            ),
          ),
          if (v.colorCodes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final hex in v.colorCodes)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: hexToColor(hex),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(hex, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ],
          if ((v.sku ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'SKU: ${v.sku}',
              style: const TextStyle(fontSize: 12, color: AppColors.textGray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _extrasCard() {
    return SectionCard(
      icon: Iconsax.tag,
      title: 'Tags and release',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_p.releaseDate != null)
            _kv('Release date',
                _p.releaseDate!.toIso8601String().substring(0, 10)),
          if (_p.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _p.tags) BlackChip(label: t, onRemove: null),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _seoCard() {
    return SectionCard(
      icon: Icons.search,
      title: 'SEO',
      child: Column(
        children: [
          _kv('Title', _p.seoTitle),
          _kv('Description', _p.seoDescription),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- helpers

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink.withOpacity(0.06)),
        ),
        child: child,
      );

  Widget _pill(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      );

  /// A "label: value" row. Skipped when the value is empty.
  Widget _kv(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textGray),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}