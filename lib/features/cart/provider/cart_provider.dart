// lib/features/cart/provider/cart_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/models/cart_models.dart';
import 'package:yanzee_app/data/services/cart_api_service.dart';

class CartState {
  final CartData data;

  /// First load / pull-to-refresh.
  final bool isLoading;

  /// A change (select, quantity, ...) is being sent to the server.
  final bool isBusy;

  /// Why the cart could not be loaded.
  final Object? error;

  /// A one-time message for a failed change. The Cart screen shows it
  /// in a snack bar and then calls clearMessage().
  final String? message;

  const CartState({
    this.data = CartData.empty,
    this.isLoading = false,
    this.isBusy = false,
    this.error,
    this.message,
  });

  CartState copyWith({
    CartData? data,
    bool? isLoading,
    bool? isBusy,
    Object? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return CartState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  final CartApiService _api = CartApiService();

  bool _alive = true;
  bool _wasLoggedIn = false;
  int _inFlight = 0;
  int _reloadSeq = 0;

  @override
  CartState build() {
    _alive = true;
    _wasLoggedIn = AuthState.instance.isLoggedIn;

    // Follow login / logout by itself: load the cart after login, empty it
    // after logout.
    AuthState.instance.addListener(_onAuthChanged);
    ref.onDispose(() {
      _alive = false;
      AuthState.instance.removeListener(_onAuthChanged);
    });

    if (_wasLoggedIn) Future.microtask(refresh);
    return const CartState();
  }

  void _onAuthChanged() {
    final nowLoggedIn = AuthState.instance.isLoggedIn;
    if (nowLoggedIn == _wasLoggedIn) return; // profile/address edits etc.
    _wasLoggedIn = nowLoggedIn;
    if (nowLoggedIn) {
      refresh();
    } else {
      clear();
    }
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// GET /carts
  Future<void> refresh() async {
    if (!AuthState.instance.isLoggedIn) {
      clear();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _reload();
    } catch (e) {
      if (!_alive) return;
      final text = _messageOf(e);
      state = state.copyWith(error: text, message: text);
    }
    if (_alive) state = state.copyWith(isLoading: false);
  }

  /// Fetches the cart and replaces the state. If several reloads overlap,
  /// only the newest one is applied.
  Future<void> _reload() async {
    final seq = ++_reloadSeq;
    final json = await _api.fetchCart();
    if (!_alive || seq != _reloadSeq) return;
    state = state.copyWith(data: CartData.fromJson(json), clearError: true);
  }

  /// Local reset only (logout / login). Does not call the server.
  void clear() {
    _reloadSeq++;
    state = const CartState();
  }

  void clearMessage() {
    if (state.message != null) state = state.copyWith(clearMessage: true);
  }

  // ---------------------------------------------------------------------------
  // Changes. Each one updates the screen at once, sends the request, then
  // reloads the real cart from the server. Returns an error text or null.
  // ---------------------------------------------------------------------------

  /// POST /carts/items
  Future<String?> addItem({required String variantId, int quantity = 1}) {
    return _mutate(
      request: () => _api.addItem(variantId: variantId, quantity: quantity),
      showMessage: false, // the caller shows its own snack bar
    );
  }

  /// PATCH /carts/items/:itemId  (quantity)
  Future<String?> setQuantity(CartItem item, int quantity) {
    final current = _latest(item);
    final max = current.stock < 1 ? 1 : current.stock;
    final q = quantity < 1 ? 1 : (quantity > max ? max : quantity);
    if (q == current.quantity) return Future.value(null);

    return _mutate(
      optimistic: (d) => d.mapItems(
        (shop, i) => i.itemId == current.itemId ? i.copyWith(quantity: q) : i,
      ),
      request: () => _api.updateItem(
        current.itemId,
        quantity: q,
        isSelected: current.isSelected,
      ),
    );
  }

  /// PATCH /carts/items/:itemId  (isSelected)
  Future<String?> setItemSelected(CartItem item, bool selected) {
    final current = _latest(item);
    return _mutate(
      optimistic: (d) => d.mapItems(
        (shop, i) =>
            i.itemId == current.itemId ? i.copyWith(isSelected: selected) : i,
      ),
      request: () => _api.updateItem(
        current.itemId,
        quantity: current.quantity,
        isSelected: selected,
      ),
    );
  }

  /// PATCH /carts/select-shop
  Future<String?> setShopSelected(CartShop shop, bool selected) {
    return _mutate(
      optimistic: (d) => d.mapItems(
        (s, i) => s.shopId == shop.shopId ? i.copyWith(isSelected: selected) : i,
      ),
      request: () => _api.selectShop(shop.shopId, selected),
    );
  }

  /// PATCH /carts/select-all
  Future<String?> setAllSelected(bool selected) {
    return _mutate(
      optimistic: (d) => d.mapItems((s, i) => i.copyWith(isSelected: selected)),
      request: () => _api.selectAll(selected),
    );
  }

  /// DELETE /carts/items/:itemId
  Future<String?> removeItem(CartItem item) {
    final current = _latest(item);
    return _mutate(
      optimistic: (d) => d.removeItems({current.itemId}),
      request: () => _api.removeItem(current.itemId),
    );
  }

  /// DELETE /carts/items/:itemId for every selected item.
  Future<String?> removeSelected() {
    final ids = state.data.items
        .where((i) => i.isSelected)
        .map((i) => i.itemId)
        .toList();
    if (ids.isEmpty) return Future.value(null);

    return _mutate(
      optimistic: (d) => d.removeItems(ids.toSet()),
      request: () async {
        await Future.wait(ids.map(_api.removeItem));
      },
    );
  }

  /// DELETE /carts
  Future<String?> emptyCart() {
    return _mutate(
      optimistic: (_) => CartData.empty,
      request: _api.clearCart,
    );
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  CartItem _latest(CartItem item) {
    for (final i in state.data.items) {
      if (i.itemId == item.itemId) return i;
    }
    return item;
  }

  Future<String?> _mutate({
    CartData Function(CartData current)? optimistic,
    required Future<void> Function() request,
    bool showMessage = true,
  }) async {
    if (!AuthState.instance.isLoggedIn) return 'Please log in first';

    _inFlight++;
    state = state.copyWith(
      isBusy: true,
      data: optimistic == null ? null : optimistic(state.data),
    );

    String? error;
    try {
      await request();
    } catch (e) {
      error = _messageOf(e);
    }
    // Always reload: it shows the real cart, and it undoes the instant
    // update if the request failed.
    try {
      await _reload();
    } catch (e) {
      error ??= _messageOf(e);
    }

    _inFlight--;
    if (!_alive) return error;
    state = state.copyWith(
      isBusy: _inFlight > 0,
      message: showMessage ? error : null,
    );
    return error;
  }

  String _messageOf(Object e) {
    if (e is CartApiException) return e.message;
    if (e is TimeoutException) {
      return 'The server took too long to answer. Please try again.';
    }
    final text = e.toString();
    if (text.contains('SocketException') || text.contains('ClientException')) {
      return 'No internet connection.';
    }
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

/// Total quantity in the cart, for the badge on the Cart tab.
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.select((s) => s.data.totalItems));
});