import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/repositories/cart_repository.dart';
import 'package:yanzee_app/data/repositories/cart_repository_impl.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return InMemoryCartRepository(); // swap this one line when the real API arrives
});

class CartNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  Future<void> toggle(int productId) async {
    final repo = ref.read(cartRepositoryProvider);
    if (state.contains(productId)) {
      await repo.remove(productId);
      state = {...state}..remove(productId);
    } else {
      await repo.add(productId);
      state = {...state, productId};
    }
  }

  bool isInCart(int productId) => state.contains(productId);
}

final cartProvider = NotifierProvider<CartNotifier, Set<int>>(
  CartNotifier.new,
);