import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';
import 'package:yanzee_app/features/shop/services/shop_api_service.dart';

final shopApiServiceProvider = Provider((ref) => ShopApiService());

/// Every shop the owner has (GET /stores).
final myShopsProvider = FutureProvider.autoDispose<List<SellerShop>>(
  (ref) => ref.watch(shopApiServiceProvider).getMyShops(),
);

/// The shop the owner picked in the drawer. null = use the first one.
final selectedShopIdProvider = StateProvider.autoDispose<String?>((ref) => null);

final myShopProvider = FutureProvider.autoDispose<SellerShop?>((ref) async {
  final shops = await ref.watch(myShopsProvider.future);
  if (shops.isEmpty) {
    ApiClient.storeId = null;
    return null;
  }
  final id = ref.watch(selectedShopIdProvider);
  final shop = shops.firstWhere((s) => s.id == id, orElse: () => shops.first);
  ApiClient.storeId = shop.id; // every request now carries x-store-id
  return shop;
});