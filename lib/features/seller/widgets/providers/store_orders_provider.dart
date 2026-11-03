import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yanzee_app/data/models/store_order.dart';
import 'package:yanzee_app/data/services/store_order_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

/// Filters of the orders list.
typedef StoreOrderFilter = ({
  String search,
  String? status,
  String? channel,
  DateTimeRange? range,
});
const StoreOrderFilter kNoStoreOrderFilter =
    (search: '', status: null, channel: null, range: null);

final storeOrderFilterProvider =
    StateProvider.autoDispose<StoreOrderFilter>((ref) => kNoStoreOrderFilter);

class StoreOrdersState {
  final List<StoreOrderRow> items;
  final int total;
  final int page; // last page that was loaded
  final int totalPages;
  final bool loadingMore;

  const StoreOrdersState({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
    this.loadingMore = false,
  });

  bool get hasMore => page < totalPages;

  StoreOrdersState copyWith({
    List<StoreOrderRow>? items,
    int? total,
    int? page,
    int? totalPages,
    bool? loadingMore,
  }) =>
      StoreOrdersState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class StoreOrdersNotifier extends AsyncNotifier<StoreOrdersState> {
  static const _limit = 20;

  @override
  Future<StoreOrdersState> build() async {
    // Runs again when a filter or the selected shop changes.
    final api = ref.watch(storeOrderApiServiceProvider);
    final f = ref.watch(storeOrderFilterProvider);
    final shop = await ref.watch(myShopProvider.future);
    if (shop == null) {
      return const StoreOrdersState(items: [], total: 0, page: 1, totalPages: 1);
    }
    final p = await api.getOrders(
      shop.id,
      page: 1,
      limit: _limit,
      search: f.search,
      status: f.status,
      channel: f.channel,
      range: f.range,
    );
    return StoreOrdersState(
      items: p.orders,
      total: p.total,
      page: p.page,
      totalPages: p.totalPages,
    );
  }

  /// Loads the next page when the user scrolls near the bottom.
  Future<void> loadMore() async {
    final current = state.asData?.value;
    final storeId = ref.read(myShopProvider).value?.id;
    if (current == null ||
        storeId == null ||
        !current.hasMore ||
        current.loadingMore) {
      return;
    }

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final f = ref.read(storeOrderFilterProvider);
      final next = await ref.read(storeOrderApiServiceProvider).getOrders(
            storeId,
            page: current.page + 1,
            limit: _limit,
            search: f.search,
            status: f.status,
            channel: f.channel,
            range: f.range,
          );
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...next.orders],
          total: next.total,
          page: current.page + 1,
          totalPages: next.totalPages,
          loadingMore: false,
        ),
      );
    } catch (_) {
      final latest = state.asData?.value ?? current;
      state = AsyncData(latest.copyWith(loadingMore: false));
    }
  }
}

// retry: null, so a failed request shows an error instead of loading forever.
final storeOrdersProvider = AsyncNotifierProvider.autoDispose<
    StoreOrdersNotifier, StoreOrdersState>(
  StoreOrdersNotifier.new,
  retry: (retryCount, error) => null,
);

/// One order with all its details.
final storeOrderDetailProvider = FutureProvider.autoDispose
    .family<StoreOrderDetail?, String>((ref, id) async {
  final shop = await ref.watch(myShopProvider.future);
  if (shop == null) return null;
  return ref.watch(storeOrderApiServiceProvider).getOrder(shop.id, id);
});