import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';
import 'package:yanzee_app/features/shop/services/shop_api_service.dart';

final shopApiServiceProvider = Provider((ref) => ShopApiService());

// autoDispose: when the owner leaves the seller area (e.g. logs out),
// the cached shop is dropped, so the next owner never sees the old one.
final myShopProvider = FutureProvider.autoDispose<SellerShop?>(
  (ref) => ref.watch(shopApiServiceProvider).getMyShop(),
);