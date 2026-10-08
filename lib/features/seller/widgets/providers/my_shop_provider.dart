import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';
import 'package:yanzee_app/features/shop/services/shop_api_service.dart';

final shopApiServiceProvider = Provider((ref) => ShopApiService());

/// Every shop the owner has (GET /stores).
final myShopsProvider = FutureProvider.autoDispose<List<SellerShop>>(
  (ref) => ref.watch(shopApiServiceProvider).getMyShops(),
);

/// The shop the owner picked in the drawer. null = use the first one.
final selectedShopIdProvider = StateProvider.autoDispose<String?>((ref) => null);

// Same shape as before (one shop, or null), so the gate and
// sellerStoreProvider keep working unchanged.
final myShopProvider = FutureProvider.autoDispose<SellerShop?>((ref) async {
  final shops = await ref.watch(myShopsProvider.future);
  if (shops.isEmpty) return null;
  final id = ref.watch(selectedShopIdProvider);
  return shops.firstWhere((s) => s.id == id, orElse: () => shops.first);
});