import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State is now productId -> quantity, instead of just a Set<int>.
class CartNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => {};

  /// Used by ProductCard's quick-add icon and Product Detail's Add/Remove button.
  void toggle(int productId) {
    final updated = Map<int, int>.from(state);
    if (updated.containsKey(productId)) {
      updated.remove(productId);
    } else {
      updated[productId] = 1;
    }
    state = updated;
  }

  void increment(int productId) {
    final updated = Map<int, int>.from(state);
    updated[productId] = (updated[productId] ?? 0) + 1;
    state = updated;
  }

  void decrement(int productId) {
    final updated = Map<int, int>.from(state);
    final current = updated[productId] ?? 0;
    if (current <= 1) {
      updated.remove(productId);
    } else {
      updated[productId] = current - 1;
    }
    state = updated;
  }

  void removeIds(Iterable<int> productIds) {
    final updated = Map<int, int>.from(state);
    for (final id in productIds) {
      updated.remove(id);
    }
    state = updated;
  }

  /// Wipes the cart. Call this on logout (and on login) so one account's
  /// cart never leaks into another account's session.
  void clear() {
    state = {};
  }
}

final cartProvider = NotifierProvider<CartNotifier, Map<int, int>>(CartNotifier.new);