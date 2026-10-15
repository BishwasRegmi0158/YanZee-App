import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yanzee_app/data/models/customer.dart';
import 'package:yanzee_app/data/services/customer_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

/// The text typed in the customers search box (empty = everyone).
final customerSearchProvider = StateProvider.autoDispose<String>((ref) => '');

class CustomersState {
  final List<Customer> items;
  final int totalCount;
  final int page; // last page that was loaded
  final bool loadingMore;

  const CustomersState({
    required this.items,
    required this.totalCount,
    required this.page,
    this.loadingMore = false,
  });

  bool get hasMore => items.length < totalCount;

  CustomersState copyWith({
    List<Customer>? items,
    int? totalCount,
    int? page,
    bool? loadingMore,
  }) =>
      CustomersState(
        items: items ?? this.items,
        totalCount: totalCount ?? this.totalCount,
        page: page ?? this.page,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class SellerCustomersNotifier extends AsyncNotifier<CustomersState> {
  static const _limit = 20;

  @override
  Future<CustomersState> build() async {
    // Runs again when the search text or the selected shop changes.
    final api = ref.watch(customerApiServiceProvider);
    final query = ref.watch(customerSearchProvider);
    final shop = await ref.watch(myShopProvider.future);
    if (shop == null) {
      return const CustomersState(items: [], totalCount: 0, page: 1);
    }
    final page = await api.getCustomers(
      shop.id,
      page: 1,
      limit: _limit,
      search: query,
    );
    return CustomersState(
      items: page.items,
      totalCount: page.totalCount,
      page: 1,
    );
  }

  CustomerApiService get _api => ref.read(customerApiServiceProvider);
  String? get _storeId => ref.read(myShopProvider).value?.id;

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _reload(String storeId) async {
    try {
      final page = await _api.getCustomers(
        storeId,
        page: 1,
        limit: _limit,
        search: ref.read(customerSearchProvider),
      );
      state = AsyncData(
        CustomersState(items: page.items, totalCount: page.totalCount, page: 1),
      );
    } catch (_) {
      // The save worked; keep showing the old list.
    }
  }

  /// Loads the next page when the user scrolls near the bottom.
  Future<void> loadMore() async {
    final current = state.asData?.value;
    final storeId = _storeId;
    if (current == null ||
        storeId == null ||
        !current.hasMore ||
        current.loadingMore) {
      return;
    }

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _api.getCustomers(
        storeId,
        page: current.page + 1,
        limit: _limit,
        search: ref.read(customerSearchProvider),
      );
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...next.items],
          totalCount: next.totalCount,
          page: current.page + 1,
          loadingMore: false,
        ),
      );
    } catch (_) {
      final latest = state.asData?.value ?? current;
      state = AsyncData(latest.copyWith(loadingMore: false));
    }
  }

  /// Returns null on success, or an error message.
  Future<String?> create({
    required String name,
    String? phone,
    String? email,
  }) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    try {
      await _api.createCustomer(storeId, name: name, phone: phone, email: email);
    } catch (e) {
      return _msg(e);
    }
    await _reload(storeId);
    return null;
  }

  /// Sends only the fields that changed. Returns null on success, or an
  /// error message.
  Future<String?> updateCustomer(
    Customer original, {
    required String name,
    String? phone,
    String? email,
  }) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';

    final changes = <String, dynamic>{
      if (name != original.name) 'name': name,
      if (phone != original.phone) 'phone': phone,
      if (email != original.email) 'email': email,
    };
    if (changes.isEmpty) return null;

    try {
      await _api.updateCustomer(storeId, original.id, changes);
    } catch (e) {
      return _msg(e);
    }

    final current = state.asData?.value;
    if (current != null) {
      final updated = Customer(
        id: original.id,
        name: name,
        phone: phone,
        email: email,
        createdAt: original.createdAt,
      );
      state = AsyncData(
        current.copyWith(
          items: [
            for (final c in current.items) c.id == original.id ? updated : c,
          ],
        ),
      );
    }
    return null;
  }

  /// Removes it at once, puts it back if the server refuses.
  Future<String?> delete(Customer customer) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    final previous = state.asData?.value;
    if (previous != null) {
      state = AsyncData(
        previous.copyWith(
          items: previous.items.where((c) => c.id != customer.id).toList(),
          totalCount: math.max(0, previous.totalCount - 1),
        ),
      );
    }
    try {
      await _api.deleteCustomer(storeId, customer.id);
      return null;
    } catch (e) {
      if (previous != null) state = AsyncData(previous);
      return _msg(e);
    }
  }
}

// retry: null, so a failed request shows an error instead of loading forever.
final sellerCustomersProvider = AsyncNotifierProvider.autoDispose<
    SellerCustomersNotifier, CustomersState>(
  SellerCustomersNotifier.new,
  retry: (retryCount, error) => null,
);