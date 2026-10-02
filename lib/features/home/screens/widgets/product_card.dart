// lib/features/home/screens/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/core/widgets/add_to_cart_animator.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/auth/screens/login_screen.dart';
import 'package:yanzee_app/features/cart/provider/cart_icon_key_provider.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
import 'package:yanzee_app/features/cart/widgets/cart_actions.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';
import 'package:yanzee_app/features/wishlist/provider/wishlist_icon_key_provider.dart';
import 'package:yanzee_app/features/wishlist/provider/wishlist_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  static const _animationDuration = Duration(milliseconds: 150);
  static const _borderRadius = 12.0;
  static const _hoverScale = 1.03;

  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _heartButtonKey = GlobalKey();

  bool _isHovered = false;
  bool _isAdding = false;

  void _setHovered(bool value) {
    if (_isHovered != value) {
      setState(() => _isHovered = value);
    }
  }

  void _openProductDetail() {
    context.push('/product/${widget.product.id}', extra: widget.product);
  }

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

  Future<void> _addToCart() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    final added = await addProductToCart(context, ref, widget.product);
    if (!mounted) return;
    setState(() => _isAdding = false);

    if (added) {
      FlyToTargetAnimator.fly(
        context: context,
        startKey: _imageKey,
        endKey: ref.read(cartIconKeyProvider),
        child: widget.product.imageUrl.isEmpty
            ? Container(color: Colors.grey.shade200)
            : Image.network(widget.product.imageUrl, fit: BoxFit.cover),
      );
    }
  }

  void _handleCartTap(bool isInCart) {
    if (isInCart) {
      // Quantity changes and removal happen on the Cart screen.
      showCartSnack(context, 'Already in your cart');
      return;
    }
    _requireLogin(context, _addToCart);
  }

  void _handleToggleWishlist(bool isWishlisted) {
    _requireLogin(context, () {
      if (!isWishlisted) {
        FlyToTargetAnimator.fly(
          context: context,
          startKey: _heartButtonKey,
          endKey: ref.read(wishlistIconKeyProvider),
          size: 34,
          child: Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: const Icon(Iconsax.heart5, color: Colors.red, size: 20),
          ),
        );
      }
      ref.read(wishlistProvider.notifier).toggle(widget.product.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isWishlisted = ref.watch(wishlistProvider).contains(product.id);
    final isInCart = ref.watch(
      cartProvider.select((s) => s.data.containsProduct(product.id)),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedScale(
        scale: _isHovered ? _hoverScale : 1.0,
        duration: _animationDuration,
        curve: Curves.easeOut,
        child: InkWell(
          borderRadius: BorderRadius.circular(_borderRadius),
          onTap: _openProductDetail,
          child: AnimatedContainer(
            duration: _animationDuration,
            clipBehavior: Clip.antiAlias,
            decoration: _cardDecoration(_isHovered),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ProductImage(
                    imageKey: _imageKey,
                    heartButtonKey: _heartButtonKey,
                    product: product,
                    isWishlisted: isWishlisted,
                    isInCart: isInCart,
                    isAdding: _isAdding,
                    onToggleWishlist: () => _handleToggleWishlist(isWishlisted),
                    onToggleCart: () => _handleCartTap(isInCart),
                  ),
                ),
                _ProductInfo(product: product),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isHovered) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isHovered ? 0.15 : 0.05),
          blurRadius: isHovered ? 16 : 8,
          offset: Offset(0, isHovered ? 6 : 2),
        ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.imageKey,
    required this.heartButtonKey,
    required this.product,
    required this.isWishlisted,
    required this.isInCart,
    required this.isAdding,
    required this.onToggleWishlist,
    required this.onToggleCart,
  });

  final GlobalKey imageKey;
  final GlobalKey heartButtonKey;
  final Product product;
  final bool isWishlisted;
  final bool isInCart;
  final bool isAdding;
  final VoidCallback onToggleWishlist;
  final VoidCallback onToggleCart;

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: const Icon(Iconsax.gallery_slash),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: imageKey,
          child: product.imageUrl.isEmpty
              ? _placeholder()
              : Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
        ),
        if (!product.inStock)
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Out of stock',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: _IconToggleButton(
            key: heartButtonKey,
            icon: isWishlisted ? Iconsax.heart5 : Iconsax.heart,
            iconColor: isWishlisted ? Colors.red : Colors.grey,
            backgroundColor: Colors.white,
            onTap: onToggleWishlist,
          ),
        ),
        Positioned(
          bottom: 6,
          right: 6,
          child: isAdding
              ? Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _IconToggleButton(
                  icon: isInCart
                      ? Iconsax.shopping_cart5
                      : Iconsax.shopping_cart,
                  iconColor: isInCart ? Colors.red : Colors.grey,
                  backgroundColor: Colors.white,
                  onTap: onToggleCart,
                ),
        ),
      ],
    );
  }
}

class _IconToggleButton extends StatelessWidget {
  const _IconToggleButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 16),
      ),
    );
  }
}

class _ProductInfo extends ConsumerWidget {
  const _ProductInfo({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One request per shop: Riverpod caches the family by shopId.
    final shopName = ref.watch(shopNameProvider(product.shopId)).value ?? '';

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 13,
            child: Text(
              shopName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: Text(
                  formatPrice(product.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (product.hasDiscount) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    formatPrice(product.originalPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}