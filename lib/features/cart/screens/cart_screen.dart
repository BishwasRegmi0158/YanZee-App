// lib/features/cart/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/provider/main_tab_provider.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/models/cart_models.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/auth/screens/widgets/login_prompt_sheet.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
import 'package:yanzee_app/features/cart/widgets/cart_actions.dart';
import 'package:yanzee_app/features/checkout/screens/checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      if (AuthState.instance.isLoggedIn) {
        ref.read(cartProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final data = cart.data;
    final loggedIn = AuthState.instance.isLoggedIn;

    // Show a failed change (for example "Cart item not found") once.
    ref.listen<CartState>(cartProvider, (previous, next) {
      final message = next.message;
      if (message != null && message != previous?.message) {
        showCartSnack(context, message);
        Future.microtask(() => ref.read(cartProvider.notifier).clearMessage());
      }
    });

    Widget body;
    if (!loggedIn) {
      body = const _EmptyCart(loggedIn: false);
    } else if (cart.isLoading && data.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (cart.error != null && data.isEmpty) {
      body = _ErrorView(
        message: cart.error.toString(),
        onRetry: () => ref.read(cartProvider.notifier).refresh(),
      );
    } else if (data.isEmpty) {
      body = const _EmptyCart(loggedIn: true);
    } else {
      body = _CartBody(cart: cart);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: body,
    );
  }
}

class _CartBody extends ConsumerWidget {
  const _CartBody({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final data = cart.data;
    final notifier = ref.read(cartProvider.notifier);
    final hasSelection = data.items.any((i) => i.isSelected);

    return Column(
      children: [
        if (cart.isBusy) const LinearProgressIndicator(minHeight: 2),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Checkbox(
                value: data.allSelected,
                onChanged: (v) => notifier.setAllSelected(v == true),
              ),
              Text(
                'SELECT ALL (${data.lineCount} ITEM(S))',
                style: context.text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: !hasSelection
                    ? null
                    : () => _confirmDelete(context, notifier, data),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('DELETE'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
              itemCount: data.shops.length,
              itemBuilder: (context, index) =>
                  _ShopSection(shop: data.shops[index]),
            ),
          ),
        ),
        _CheckoutBar(data: data),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    CartNotifier notifier,
    CartData data,
  ) {
    final count = data.items.where((i) => i.isSelected).length;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove items?'),
        content: Text(
          'Remove $count selected item${count == 1 ? '' : 's'} from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              notifier.removeSelected();
            },
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.colors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ShopSection extends ConsumerWidget {
  const _ShopSection({required this.shop});

  final CartShop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Checkbox(
                  value: shop.allSelected,
                  onChanged: (v) => notifier.setShopSelected(shop, v == true),
                ),
                Icon(
                  Icons.storefront_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    shop.shopName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final item in shop.items) _CartRow(item: item),
        ],
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  const _CartRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notifier = ref.read(cartProvider.notifier);
    final image = item.image;
    final note = item.warning ??
        (item.isLowStock ? '${item.stock} item(s) left' : null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Checkbox(
              value: item.isSelected,
              onChanged: (v) => notifier.setItemSelected(item, v == true),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (image == null || image.isEmpty)
                ? _thumbPlaceholder(context)
                : Image.network(
                    image,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbPlaceholder(context),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Size: ${item.size}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPrice(item.effectivePrice),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    if (item.hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        formatPrice(item.unitPrice),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: TextStyle(fontSize: 12, color: colors.error),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove,
                      onTap: item.quantity > 1
                          ? () => notifier.setQuantity(item, item.quantity - 1)
                          : null,
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add,
                      onTap: item.canIncrease
                          ? () => notifier.setQuantity(item, item.quantity + 1)
                          : null,
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remove',
                      icon: Icon(
                        Icons.delete_outline,
                        color: colors.onSurfaceVariant,
                      ),
                      onPressed: () => notifier.removeItem(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder(BuildContext context) => Container(
        width: 72,
        height: 72,
        color: context.colors.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: context.colors.onSurfaceVariant,
        ),
      );
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? colors.surfaceContainerHighest
              : colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? colors.onSurface
              : colors.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.data});

  final CartData data;

  /// Stopgap: CheckoutItem still wants a Product, so build a small one from
  /// the cart row. This goes away when the checkout/order API is wired.
  Product _asProduct(CartItem item, String shopId) {
    return Product(
      id: item.productId,
      shopId: shopId,
      name: item.productName,
      category: '',
      status: 'ACTIVE',
      audience: '',
      imageUrl: item.image ?? '',
      gallery: const [],
      totalStock: item.stock,
      originalPrice: item.unitPrice,
      salePrice: item.discountPrice,
      variants: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = data.selectedCount;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count item${count == 1 ? '' : 's'} selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formatPrice(data.grandTotal),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  disabledBackgroundColor: colors.surfaceContainerHighest,
                  disabledForegroundColor: colors.onSurfaceVariant,
                ),
                onPressed: count == 0
                    ? null
                    : () {
                        final items = <CheckoutItem>[];
                        for (final shop in data.shops) {
                          for (final item in shop.items) {
                            if (!item.isSelected) continue;
                            items.add(
                              CheckoutItem(
                                product: _asProduct(item, shop.shopId),
                                quantity: item.quantity,
                              ),
                            );
                          }
                        }
                        if (items.isNotEmpty) {
                          context.push(
                            CheckoutScreen.routeName,
                            extra: <String, dynamic>{'items': items},
                          );
                        }
                      },
                child: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: colors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load your cart',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends ConsumerWidget {
  const _EmptyCart({required this.loggedIn});

  final bool loggedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              loggedIn ? 'Your cart is empty' : 'Log in to see your cart',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              loggedIn
                  ? 'Add products to your cart to see them here.'
                  : 'Your cart is saved to your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: () async {
                final ok = await requireLogin(context);
                if (!ok) return;
                if (loggedIn) {
                  ref.read(mainTabIndexProvider.notifier).state = kShopTabIndex;
                }
              },
              child: Text(loggedIn ? 'Browse products' : 'Log in'),
            ),
          ],
        ),
      ),
    );
  }
}