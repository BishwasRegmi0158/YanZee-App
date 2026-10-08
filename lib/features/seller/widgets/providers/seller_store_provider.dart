import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yanzee_app/data/models/seller_store.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/shop/services/shop_api_service.dart';

class SellerStoreNotifier extends StateNotifier<SellerStore> {
  SellerStoreNotifier(this._api, this._storeId, SellerStore initial)
      : super(initial);

  final ShopApiService _api;
  final String _storeId;

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');


  Future<String?> updateField({
    String? name,
    String? category,
    String? contactEmail,
  }) async {
    if (_storeId.isEmpty) return 'No store loaded.';

    final previous = state;
    state = state.copyWith(
      name: name,
      category: category,
      contactEmail: contactEmail,
    ); // show the change immediately

    try {
      await _api.updateMyShop(
        _storeId,
        name: name,
        category: category,
        contactEmail: contactEmail,
      );
      return null;
    } catch (e) {
      if (mounted) state = previous; // roll back
      return _msg(e);
    }
  }

  /// POST /images/store-logo. The server saves the logo and returns its URL.
  Future<String?> updateLogo(File file) async {
    if (_storeId.isEmpty) return 'No store loaded.';

    final previous = state;
    state = state.copyWith(logoImage: file); // instant preview

    try {
      final url = await _api.uploadStoreLogo(_storeId, file);
      if (mounted) state = state.copyWith(logoUrl: url);
      return null;
    } catch (e) {
      if (mounted) state = previous;
      return _msg(e);
    }
  }

  /// Not supported by the backend yet. When a remove-logo endpoint exists,
  /// call it here (this is the only place that needs to change).
  Future<String?> removeLogo() async {
    return 'Removing the logo is not available yet. Choose a new image to replace it.';
  }
}

// autoDispose: leaving the seller area (e.g. logout) clears this, so the
// next owner never sees the previous owner's store.
final sellerStoreProvider =
    StateNotifierProvider.autoDispose<SellerStoreNotifier, SellerStore>((ref) {
  final shop = ref.watch(myShopProvider).value;
  final api = ref.watch(shopApiServiceProvider);

  return SellerStoreNotifier(
    api,
    shop?.id ?? '',
    SellerStore(
      name: shop?.name ?? '',
      category: shop?.category ?? '',
      contactEmail: shop?.contactEmail,
      status: shop?.status ?? '',
      isPublished: shop?.isPublished ?? false,
      logoUrl: shop?.logo,
    ),
  );
});