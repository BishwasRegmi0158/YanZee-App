import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';
import 'package:yanzee_app/features/home/screens/widgets/product_card.dart';
import 'package:yanzee_app/features/wishlist/provider/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistIds = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Wishlist',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: wishlistIds.isEmpty
          ? _EmptyWishlist()
          : _WishlistBody(wishlistIds: wishlistIds),
    );
  }
}

class _WishlistBody extends ConsumerWidget {
  final Iterable<int> wishlistIds;

  const _WishlistBody({required this.wishlistIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsyncs = wishlistIds
        .map((id) => ref.watch(productByIdProvider(id)))
        .toList();

    final anyLoading = productAsyncs.any((p) => p.isLoading);
    final firstError = productAsyncs.firstWhere(
      (p) => p.hasError,
      orElse: () => productAsyncs.first,
    );

    if (anyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (firstError.hasError) {
      return Center(child: Text('Something went wrong: ${firstError.error}'));
    }

    final wishlistedProducts = productAsyncs
        .map((p) => p.value)
        .whereType<Product>()
        .toList();

    if (wishlistedProducts.isEmpty) {
      return _EmptyWishlist();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 240,
        ),
        itemCount: wishlistedProducts.length,
        itemBuilder: (context, index) {
          return ProductCard(product: wishlistedProducts[index]);
        },
      ),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Your wishlist is empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart on any product to save it here.',
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
              onPressed: () => context.go('/shop'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Browse products',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
