import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yanzee_app/data/models/inventory.dart';
import 'package:yanzee_app/data/services/inventory_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

/// Filters of the stock list. status is the API value (IN_STOCK, ...).
typedef StockFilter = ({String search, String? outletId, String? status});
const StockFilter kNoStockFilter = (search: '', outletId: null, status: null);

/// Filters of the stock history. type is the API value (STOCK_IN, STOCK_OUT).
typedef MovementFilter = ({DateTimeRange? range, String? type});
const MovementFilter kNoMovementFilter = (range: null, type: null);

final stockFilterProvider =
    StateProvider.autoDispose<StockFilter>((ref) => kNoStockFilter);

final movementFilterProvider =
    StateProvider.autoDispose<MovementFilter>((ref) => kNoMovementFilter);

/// Stock of the selected shop, filtered. Reloads when a filter changes or
/// when the shop changes.
final sellerStockProvider =
    FutureProvider.autoDispose<List<StockItem>>((ref) async {
  final filter = ref.watch(stockFilterProvider);
  final shop = await ref.watch(myShopProvider.future);
  if (shop == null) return const [];
  return ref.watch(inventoryApiServiceProvider).getStock(
        shop.id,
        search: filter.search,
        outletId: filter.outletId,
        status: filter.status,
      );
});

/// Every product and variant, unfiltered. The stock-in item picker uses this.
final allStockItemsProvider =
    FutureProvider.autoDispose<List<StockItem>>((ref) async {
  final shop = await ref.watch(myShopProvider.future);
  if (shop == null) return const [];
  return ref.watch(inventoryApiServiceProvider).getStock(shop.id);
});

/// Stock movements of the selected shop, filtered.
final stockMovementsProvider =
    FutureProvider.autoDispose<List<StockMovement>>((ref) async {
  final filter = ref.watch(movementFilterProvider);
  final shop = await ref.watch(myShopProvider.future);
  if (shop == null) return const [];
  return ref.watch(inventoryApiServiceProvider).getMovements(
        shop.id,
        from: filter.range?.start,
        to: filter.range?.end,
        type: filter.type,
      );
});