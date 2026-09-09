import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
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

  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered != value) {
      setState(() => _isHovered = value);
    }
  }

  void _openProductDetail() {
    context.push('/product/${widget.product.id}', extra: widget.product);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isWishlisted = ref.watch(wishlistProvider).contains(product.id);
    final isInCart = ref.watch(cartProvider).containsKey(product.id);

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
                    product: product,
                    isWishlisted: isWishlisted,
                    isInCart: isInCart,
                    onToggleWishlist: () =>
                        ref.read(wishlistProvider.notifier).toggle(product.id),
                    onToggleCart: () =>
                        ref.read(cartProvider.notifier).toggle(product.id),
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

/// Product image with overlaid wishlist and cart toggle buttons.
class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.product,
    required this.isWishlisted,
    required this.isInCart,
    required this.onToggleWishlist,
    required this.onToggleCart,
  });

  final Product product;
  final bool isWishlisted;
  final bool isInCart;
  final VoidCallback onToggleWishlist;
  final VoidCallback onToggleCart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          product.imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported_outlined),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: _IconToggleButton(
            icon: isWishlisted ? Icons.favorite : Icons.favorite_border,
            iconColor: isWishlisted ? Colors.red : Colors.grey,
            backgroundColor: Colors.white,
            onTap: onToggleWishlist,
          ),
        ),
        Positioned(
          bottom: 6,
          right: 6,
          child: _IconToggleButton(
            icon: isInCart ? Icons.check : Icons.add_shopping_cart_outlined,
            iconColor: isInCart ? Colors.white : Colors.grey,
            backgroundColor: isInCart ? const Color(0xFFE53935) : Colors.white,
            onTap: onToggleCart,
          ),
        ),
      ],
    );
  }
}

/// Small circular icon button used for the wishlist/cart overlays.
class _IconToggleButton extends StatelessWidget {
  const _IconToggleButton({
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

/// Brand, name, rating, and price block shown below the product image.
class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.brand.toUpperCase(),
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, size: 12, color: Colors.red),
              const SizedBox(width: 2),
              Text(
                product.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}