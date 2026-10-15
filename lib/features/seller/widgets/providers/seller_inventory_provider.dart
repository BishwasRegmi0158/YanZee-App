import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/inventory.dart';
import 'package:yanzee_app/data/services/inventory_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

/// Stock of the selected shop. Reloads when the shop changes.
final sellerStockProvider =
    FutureProvider.autoDispose<List<StockItem>>((ref) async {
  final shop = await ref.watch(myShopProvider.future);
  if (shop == null) return const [];
  return ref.watch(inventoryApiServiceProvider).getStock(shop.id);
});

/// Stock movements of the selected shop, for an optional date range.
final stockMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, DateTimeRange?>((ref, range) async {
  final shop = await ref.watch(myShopProvider.future);
  if (shop == null) return const [];
  return ref
      .watch(inventoryApiServiceProvider)
      .getMovements(shop.id, from: range?.start, to: range?.end);
});