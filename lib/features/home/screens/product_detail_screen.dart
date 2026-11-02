// lib/features/product/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/constants/categories.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_widgets.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/auth/screens/login_screen.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
import 'package:yanzee_app/features/cart/widgets/cart_actions.dart';
import 'package:yanzee_app/features/cart/widgets/variant_picker_sheet.dart';
import 'package:yanzee_app/features/checkout/screens/checkout_screen.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';
import 'package:yanzee_app/features/wishlist/provider/wishlist_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isAdding = false;
  String? _selectedVariantId;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Only one size in stock: pick it for the customer.
    final available = widget.product.availableVariants;
    if (available.length == 1) _selectedVariantId = available.first.id;
  }

  ProductVariant? get _selectedVariant {
    for (final v in widget.product.variants) {
      if (v.id == _selectedVariantId) return v;
    }
    return null;
  }

  /// If the user is logged in, runs [onSuccess] immediately.
  /// Otherwise pushes the login screen and, if login succeeds, runs
  /// [onSuccess] once we're back on this screen.
  Future<void> _requireLogin(
    BuildContext context,
    VoidCallback onSuccess,
  ) async {
    if (AuthState.instance.isLoggedIn) {
      onSuccess();
      return;
    }
    final loggedIn = await context.push<bool>(LoginScreen.routeName);
    if (loggedIn == true && mounted) {
      onSuccess();
    }
  }

  Future<void> _handleAddToCart() async {
    if (_isAdding) return;
    final variant = _selectedVariant;
    if (variant == null) {
      showCartSnack(context, 'Please select a size');
      return;
    }
    setState(() => _isAdding = true);
    final error = await ref
        .read(cartProvider.notifier)
        .addItem(variantId: variant.id, quantity: 1);
    if (!mounted) return;
    setState(() => _isAdding = false);
    showCartSnack(context, error ?? 'Added to cart');
  }

  Future<void> _handleBuyNow() async {
    final product = widget.product;
    final selection = await showVariantPickerSheet(
      context,
      product: product,
      confirmLabel: 'Confirm · Buy Now',
      initialVariantId: _selectedVariantId,
    );
    if (selection == null || !mounted) return;

    // The size (selection.variant) is not passed to checkout yet; that comes
    // with the checkout/order API.
    context.push(
      CheckoutScreen.routeName,
      extra: <String, dynamic>{
        'items': [CheckoutItem(product: product, quantity: selection.quantity)],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final product = widget.product;
    final isWishlisted = ref.watch(wishlistProvider).contains(product.id);
    final shopName = ref.watch(shopNameProvider(product.shopId)).value ?? '';
    final images = product.images;
    final selected = _selectedVariant;
    final description = product.description?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: isWishlisted ? colors.primary : null,
            ),
            onPressed: () => _requireLogin(
              context,
              () => ref.read(wishlistProvider.notifier).toggle(product),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 320,
              color: colors.surfaceContainerLowest,
              child: images.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: colors.onSurfaceVariant,
                      ),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (i) => setState(() => _imageIndex = i),
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 30,
                            ),
                            child: Image.network(
                              images[i],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 48,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (i) => Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _imageIndex
                                        ? colors.primary
                                        : colors.outline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(
                        label: categoryLabelFor(product.category).toUpperCase(),
                      ),
                      if (product.audience.isNotEmpty)
                        StatusPill(
                          label:
                              audienceLabelFor(product.audience).toUpperCase(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (shopName.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            shopName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(product.name, style: context.text.headlineLarge),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPrice(product.price),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 10),
                        Text(
                          formatPrice(product.originalPrice),
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${product.discountPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.variants.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Size',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizeChips(
                      variants: product.variants,
                      selectedId: _selectedVariantId,
                      onSelected: (v) =>
                          setState(() => _selectedVariantId = v.id),
                    ),
                    if (selected != null && selected.stock <= 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Only ${selected.stock} left',
                          style: TextStyle(fontSize: 12, color: colors.error),
                        ),
                      ),
                  ],
                  if (!product.inStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Out of stock',
                        style: TextStyle(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_isAdding || !product.inStock)
                        ? null
                        : () => _requireLogin(context, _handleAddToCart),
                    icon: _isAdding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: colors.surfaceContainerHighest,
                      disabledForegroundColor: colors.onSurfaceVariant,
                    ),
                    onPressed: product.inStock
                        ? () => _requireLogin(context, _handleBuyNow)
                        : null,
                    child: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}