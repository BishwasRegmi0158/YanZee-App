import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_products_provider.dart';
import 'package:yanzee_app/features/seller/widgets/screens/product_form_screen.dart';

class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> {
  String _query = '';

  void _openForm({SellerProduct? initial}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(initial: initial)),
    );
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
      ref.read(sellerProductsProvider.notifier).deleteProduct(p.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.tick_circle, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '"${p.name}" deleted',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  (Color bg, Color fg) _statusColors(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return (Colors.green.withOpacity(0.1), Colors.green.shade700);
      case ProductStatus.draft:
        return (Colors.grey.shade200, Colors.grey.shade600);
      case ProductStatus.outOfStock:
        return (Colors.red.withOpacity(0.1), Colors.red.shade700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(sellerProductsProvider);
    final isNarrow = Responsive.isSmallPhone(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      body: SafeArea(
        child: productsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (e, _) => Center(child: Text('Failed to load products: $e')),
          data: (products) {
            final filtered = _query.isEmpty
                ? products
                : products
                      .where(
                        (p) =>
                            p.name.toLowerCase().contains(_query.toLowerCase()) ||
                            p.category.toLowerCase().contains(
                              _query.toLowerCase(),
                            ),
                      )
                      .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              children: [
                _HeaderRow(
                  isNarrow: isNarrow,
                  itemCount: products.length,
                  onAdd: () => _openForm(),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(
                      Iconsax.search_normal_1,
                      size: 20,
                      color: AppColors.textGray,
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Iconsax.box, size: 44, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            products.isEmpty
                                ? 'No products yet'
                                : 'No products match "$_query"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textGray),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (p) => _ProductCard(
                      product: p,
                      statusColors: _statusColors(p.status),
                      onEdit: () => _openForm(initial: p),
                      onDelete: () => _confirmDelete(p),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Title + item count on the left, Add button on the right. On very
/// narrow phones the button drops to its own row below the title instead
/// of squeezing next to it, which is what caused the overflow before.
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
          '$itemCount item${itemCount == 1 ? '' : 's'} in your catalogue',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Iconsax.add, size: 18),
      label: Text('Add', style: TextStyle(fontSize: Responsive.font(context, 13))),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 12),
          addButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        addButton,
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final SellerProduct product;
  final (Color, Color) statusColors;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.statusColors,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = statusColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(),
                  )
                : _placeholderImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: Responsive.font(context, 14.5),
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.font(context, 12),
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 6),
                // Wrap already handles narrow widths by flowing to a new
                // line instead of overflowing — kept as-is, just with
                // responsive font sizes for consistency with the rest.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.font(context, 14),
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      product.stock == 0
                          ? 'No stock'
                          : '${product.stock} in stock',
                      style: TextStyle(
                        fontSize: Responsive.font(context, 12),
                        color: product.stock == 0
                            ? Colors.red.shade600
                            : AppColors.textGray,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.status.label,
                        style: TextStyle(
                          fontSize: Responsive.font(context, 10.5),
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Column(
            children: [
              _CircleIconButton(icon: Iconsax.edit_2, onTap: onEdit),
              const SizedBox(height: 8),
              _CircleIconButton(
                icon: Iconsax.trash,
                iconColor: Colors.red,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() => Container(
    width: 56,
    height: 56,
    color: Colors.grey.shade100,
    child: const Icon(Iconsax.gallery_slash, color: AppColors.textGray),
  );
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: (iconColor ?? AppColors.ink).withOpacity(0.25),
          ),
        ),
        child: Icon(icon, size: 16, color: iconColor ?? AppColors.ink),
      ),
    );
  }
}