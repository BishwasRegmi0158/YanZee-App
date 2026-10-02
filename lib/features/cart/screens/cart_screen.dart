// lib/features/cart/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/provider/main_tab_provider.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/models/cart_models.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/auth/screens/widgets/login_prompt_sheet.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
import 'package:yanzee_app/features/cart/widgets/cart_actions.dart';
import 'package:yanzee_app/features/checkout/screens/checkout_screen.dart';

const _accent = Color(0xFFE53935);

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
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cart',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: body,
    );
  }
}

class _CartBody extends ConsumerWidget {
  const _CartBody({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = cart.data;
    final notifier = ref.read(cartProvider.notifier);
    final hasSelection = data.items.any((i) => i.isSelected);

    return Column(
      children: [
        if (cart.isBusy)
          const LinearProgressIndicator(minHeight: 2, color: Colors.black),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Checkbox(
                value: data.allSelected,
                activeColor: Colors.black,
                onChanged: (v) => notifier.setAllSelected(v == true),
              ),
              Text(
                'SELECT ALL (${data.lineCount} ITEM(S))',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
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
                  foregroundColor: Colors.grey.shade700,
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
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
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
            child: const Text('Remove', style: TextStyle(color: _accent)),
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
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Checkbox(
                  value: shop.allSelected,
                  activeColor: Colors.black,
                  onChanged: (v) => notifier.setShopSelected(shop, v == true),
                ),
                Icon(
                  Icons.storefront_outlined,
                  size: 18,
                  color: Colors.grey.shade700,
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
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
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
              activeColor: Colors.black,
              onChanged: (v) => notifier.setItemSelected(item, v == true),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: (image == null || image.isEmpty)
                ? _thumbPlaceholder()
                : Image.network(
                    image,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbPlaceholder(),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPrice(item.effectivePrice),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _accent,
                      ),
                    ),
                    if (item.hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        formatPrice(item.unitPrice),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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
                    style: const TextStyle(fontSize: 12, color: _accent),
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
                        color: Colors.grey.shade600,
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

  Widget _thumbPlaceholder() => Container(
        width: 72,
        height: 72,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported_outlined),
      );
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFEDEDF3) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.black87 : Colors.grey.shade400,
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
    final count = data.selectedCount;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count item${count == 1 ? '' : 's'} selected',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
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
              child: const Text(
                'Checkout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey.shade400),
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: onRetry,
              child: const Text('Try again', style: TextStyle(color: Colors.white)),
            ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey.shade300,
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
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final ok = await requireLogin(context);
                if (!ok) return;
                if (loggedIn) {
                  ref.read(mainTabIndexProvider.notifier).state = kShopTabIndex;
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  loggedIn ? 'Browse products' : 'Log in',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}