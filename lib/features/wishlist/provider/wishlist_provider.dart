import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/repositories/wishlist_repository.dart';
import 'package:yanzee_app/data/repositories/wishlist_repository_impl.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return InMemoryWishlistRepository(); 
});

class WishlistNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  Future<void> toggle(int productId) async {
    final repo = ref.read(wishlistRepositoryProvider);
    if (state.contains(productId)) {
      await repo.remove(productId);
      state = {...state}..remove(productId);
    } else {
      await repo.add(productId);
      state = {...state, productId};
    }
  }

  bool isWishlisted(int productId) => state.contains(productId);
  Future<void> clear() async {
    final repo = ref.read(wishlistRepositoryProvider);
    await repo.clear();
    state = {};
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, Set<int>>(
  WishlistNotifier.new,
);