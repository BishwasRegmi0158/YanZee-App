import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/data/models/shop_category.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_brands_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_categories_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_products_provider.dart';
import 'package:yanzee_app/features/seller/widgets/screens/product_details_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/product_form_screen.dart';

const _pageBg = Color(0xFFF7F5F2);

class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> {
  String _query = '';
  final _statusFilter = ValueNotifier<String?>('all');
  late final ValueNotifier<String?> _categoryFilter;

  @override
  void initState() {
    super.initState();
    _categoryFilter = ValueNotifier<String?>(
      ref.read(productCategoryFilterProvider) ?? 'all',
    );
  }

  @override
  void dispose() {
    _statusFilter.dispose();
    _categoryFilter.dispose();
    super.dispose();
  }

  bool get _filtersActive =>
      (_statusFilter.value ?? 'all') != 'all' ||
      ref.read(productCategoryFilterProvider) != null;

  void _clearFilters() {
    _statusFilter.value = 'all';
    _categoryFilter.value = 'all';
    ref.read(productCategoryFilterProvider.notifier).state = null;
    setState(() => _query = '');
  }

  void _openForm({SellerProduct? initial}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(initial: initial)),
    );
  }

  void _openDetails(SellerProduct p) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: p)));
  }

  void _snack(String message, {bool failed = false}) {
    if (failed) {
      AppToast.error(context, message);
    } else {
      AppToast.success(context, message);
    }
  }

  Future<void> _confirmDelete(SellerProduct p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: Text(
          'Remove "${p.name}" from your catalogue? This can\'t be undone.',
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

    if (confirmed == true && mounted) {
      final error = await ref
          .read(sellerProductsProvider.notifier)
          .deleteProduct(p.id);
      if (!mounted) return;
      _snack(error ?? '"${p.name}" deleted', failed: error != null);
    }
  }

  Future<void> _changeStatus(SellerProduct p) async {
    final picked = await showModalBottomSheet<ProductStatus>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Set status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            for (final s in ProductStatus.values)
              ListTile(
                title: Text(s.label),
                trailing: s == p.status ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == p.status || !mounted) return;

    final error = await ref
        .read(sellerProductsProvider.notifier)
        .setStatus(p.id, picked);
    if (!mounted) return;
    _snack(
      error ?? '"${p.name}" set to ${picked.label}',
      failed: error != null,
    );
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

  List<SellerProduct> _apply(List<SellerProduct> all) {
    final q = _query.trim().toLowerCase();
    final status = _statusFilter.value ?? 'all';
    return all.where((p) {
      if (status != 'all' && p.status.apiValue != status) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.brandName ?? '').toLowerCase().contains(q) ||
          p.slug.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(sellerProductsProvider);
    final categoriesAsync = ref.watch(sellerCategoriesProvider);
    // Warm up the brands so the product form opens with them ready.
    ref.watch(sellerBrandsProvider);

    final isNarrow = Responsive.isSmallPhone(context);
    final total = productsAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _HeaderRow(
                isNarrow: isNarrow,
                itemCount: total,
                onAdd: () => _openForm(),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: const Icon(
                    Iconsax.search_normal_1,
                    size: 20,
                    color: AppColors.textGray,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.ink),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _statusDropdown()),
                  const SizedBox(width: 10),
                  Expanded(child: _categoryDropdown(categoriesAsync)),
                ],
              ),
            ),
            Expanded(
              child: productsAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Failed to load products: ${e.toString().replaceFirst('Exception: ', '')}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(sellerProductsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (products) => _buildList(products),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<SellerProduct> products) {
    final filtered = _apply(products);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(sellerProductsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  filtered.length == products.length
                      ? '${products.length} product${products.length == 1 ? '' : 's'}'
                      : '${filtered.length} of ${products.length} products',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ),
              if (_filtersActive || _query.isNotEmpty)
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Iconsax.box, size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    products.isEmpty && !_filtersActive
                        ? 'No products yet'
                        : 'No products match your filters',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textGray),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.ink.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < filtered.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: Colors.grey.shade200,
                      ),
                    _ProductRow(
                      product: filtered[i],
                      statusColors: _statusColors(filtered[i].status),
                      onTap: () => _openDetails(filtered[i]),
                      onStatusTap: () => _changeStatus(filtered[i]),
                      onEdit: () => _openForm(initial: filtered[i]),
                      onDelete: () => _confirmDelete(filtered[i]),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  //  filter dropdowns

  Widget _statusDropdown() {
    final items = <DropdownItem<String>>[
      _filterItem('all', 'All statuses'),
      for (final s in ProductStatus.values) _filterItem(s.apiValue, s.label),
    ];
    return _filterDropdown(
      items: items,
      notifier: _statusFilter,
      onChanged: (v) {
        _statusFilter.value = v ?? 'all';
        setState(() {});
      },
    );
  }

  Widget _categoryDropdown(AsyncValue<List<ShopCategory>> async) {
    final categories = async.value;
    if (categories == null) {
      return _filterPill(
        async.hasError ? 'Categories unavailable' : 'Loading categories...',
      );
    }
    final selected = ref.read(productCategoryFilterProvider);
    final items = <DropdownItem<String>>[
      _filterItem('all', 'All categories'),
      for (final c in categories) _filterItem(c.id, c.name),
      if (selected != null && !categories.any((c) => c.id == selected))
        _filterItem(selected, 'Selected category'),
    ];
    return _filterDropdown(
      items: items,
      notifier: _categoryFilter,
      onChanged: (v) {
        _categoryFilter.value = v ?? 'all';
        ref.read(productCategoryFilterProvider.notifier).state =
            (v == null || v == 'all') ? null : v;
      },
    );
  }

  DropdownItem<String> _filterItem(String value, String label) =>
      DropdownItem<String>(
        value: value,
        height: 42,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5),
        ),
      );

  Widget _filterPill(String text) => Container(
    height: 42,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, color: AppColors.textGray),
    ),
  );

  Widget _filterDropdown({
    required List<DropdownItem<String>> items,
    required ValueNotifier<String?> notifier,
    required ValueChanged<String?> onChanged,
  }) {
    final maxH = (MediaQuery.sizeOf(context).height * 0.38).clamp(160.0, 280.0);
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        items: items,
        valueListenable: notifier,
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 42,
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.keyboard_arrow_down_rounded),
          openMenuIcon: Icon(Icons.keyboard_arrow_up_rounded),
          iconSize: 20,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: maxH.toDouble(),
          elevation: 6,
          padding: const EdgeInsets.symmetric(vertical: 6),
          offset: const Offset(0, -2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: WidgetStateProperty.all(4),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final bool isNarrow;
  final int itemCount;
  final VoidCallback onAdd;

  const _HeaderRow({
    required this.isNarrow,
    required this.itemCount,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products',
          style: TextStyle(
            fontFamily: AppFonts.brand,
            fontSize: Responsive.font(context, 24),
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Manage everything you sell',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: Responsive.font(context, 12),
            color: AppColors.textGray,
          ),
        ),
      ],
    );

    final addButton = ElevatedButton.icon(
      onPressed: onAdd,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Iconsax.add, size: 18),
      label: Text(
        'Add',
        style: TextStyle(fontSize: Responsive.font(context, 13)),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const SizedBox(height: 12), addButton],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        addButton,
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final SellerProduct product;
  final (Color, Color) statusColors;
  final VoidCallback onTap;
  final VoidCallback onStatusTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductRow({
    required this.product,
    required this.statusColors,
    required this.onTap,
    required this.onStatusTap,
    required this.onEdit,
    required this.onDelete,
  });

  String _priceText() {
    final min = product.priceMin;
    final max = product.priceMax;
    if (product.hasVariants && min != null && max != null && min != max) {
      return '${formatPrice(min)} - ${formatPrice(max)}';
    }
    return formatPrice(product.price);
  }

  String _stockText() {
    if (product.hasVariants) {
      final n = product.variantCount;
      return '$n variant${n == 1 ? '' : 's'}';
    }
    return product.quantity == 0 ? 'No stock' : '${product.quantity} in stock';
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = statusColors;
    final noStock = !product.hasVariants && product.quantity == 0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: onStatusTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: fg,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                product.status.label,
                                style: TextStyle(
                                  fontSize: Responsive.font(context, 10.5),
                                  fontWeight: FontWeight.w600,
                                  color: fg,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, size: 14, color: fg),
                            ],
                          ),
                        ),
                      ),
                      if (!product.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Hidden',
                            style: TextStyle(
                              fontSize: Responsive.font(context, 10.5),
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: Responsive.font(context, 14.5),
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _priceText(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.font(context, 13.5),
                          color: AppColors.ink,
                        ),
                      ),
                      if (!product.hasVariants &&
                          product.crossedPrice != null &&
                          product.crossedPrice! > product.price)
                        Text(
                          formatPrice(product.crossedPrice!),
                          style: TextStyle(
                            fontSize: Responsive.font(context, 11.5),
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        _stockText(),
                        style: TextStyle(
                          fontSize: Responsive.font(context, 12),
                          color: noStock
                              ? Colors.red.shade600
                              : AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                  if (product.brandName?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.brandName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.font(context, 11.5),
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert, size: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuDivider(height: 1),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 64,
    height: 64,
    color: Colors.grey.shade100,
    child: const Icon(Iconsax.gallery_slash, color: AppColors.textGray),
  );
}