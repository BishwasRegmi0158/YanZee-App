// lib/features/wishlist/provider/wishlist_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/repositories/wishlist_repository.dart';
import 'package:yanzee_app/data/repositories/wishlist_repository_impl.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return InMemoryWishlistRepository();
});

/// The state is the set of wishlisted product ids (UUID strings), so
/// `.contains(id)` and `.length` keep working. The notifier also keeps the
/// Product objects, because the backend has no wishlist API and no public
/// "product by id" call to load them again later.
class WishlistNotifier extends Notifier<Set<String>> {
  final Map<String, Product> _products = {};

  @override
  Set<String> build() => {};

  /// Wishlisted products, in the order they were added.
  List<Product> get products =>
      state.map((id) => _products[id]).whereType<Product>().toList();

  Future<void> toggle(Product product) async {
    final repo = ref.read(wishlistRepositoryProvider);
    if (state.contains(product.id)) {
      await repo.remove(product.id);
      _products.remove(product.id);
      state = {...state}..remove(product.id);
    } else {
      await repo.add(product.id);
      _products[product.id] = product;
      state = {...state, product.id};
    }
  }

  bool isWishlisted(String productId) => state.contains(productId);

  Future<void> clear() async {
    final repo = ref.read(wishlistRepositoryProvider);
    await repo.clear();
    _products.clear();
    state = {};
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, Set<String>>(
  WishlistNotifier.new,
);