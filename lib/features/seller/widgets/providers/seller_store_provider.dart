import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yanzee_app/data/models/seller_store.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/shop/services/shop_api_service.dart';

class SellerStoreNotifier extends StateNotifier<SellerStore> {
  SellerStoreNotifier(this._api, SellerStore initial) : super(initial) {
    _fillFromSignup();
  }

  final ShopApiService _api;

  /// For shops that have no address / phone yet, show the signup values.
  /// They get saved to the shop the next time the owner edits anything.
  Future<void> _fillFromSignup() async {
    if (state.address != 'Not set' && state.contactPhone != 'Not set') return;
    try {
      final me = await _api.getMe();
      if (!mounted) return;

      final address = signupAddress(me);
      final phone = me['phone']?.toString().trim() ?? '';

      state = state.copyWith(
        address: (state.address == 'Not set' && address.isNotEmpty)
            ? address
            : null,
        contactPhone: (state.contactPhone == 'Not set' && phone.isNotEmpty)
            ? phone
            : null,
      );
    } catch (_) {
      // Keep "Not set"; the owner can still type the values in.
    }
  }

  String? _sendable(String v) => (v.isEmpty || v == 'Not set') ? null : v;

  /// Sends the whole store to PATCH /shops/my.
  Future<void> _push(SellerStore s) {
    return _api.updateMyShop(
      name: s.name,
      contactEmail: s.contactEmail,
      description: s.description,
      returnPolicy: s.returnPolicy,
      address: _sendable(s.address),
      contactPhone: _sendable(s.contactPhone),
      image: s.logoUrl,
    );
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  /// Returns null on success, or an error message to show the user.
  Future<String?> updateField({
    String? name,
    String? description,
    String? contactEmail,
    String? returnPolicy,
    String? address,
    String? contactPhone,
  }) async {
    final previous = state;
    final next = state.copyWith(
      name: name,
      description: description,
      contactEmail: contactEmail,
      returnPolicy: returnPolicy,
      address: address,
      contactPhone: contactPhone,
    );
    state = next; // show the change immediately

    try {
      await _push(next);
      return null;
    } catch (e) {
      if (mounted) state = previous; // roll back
      return _msg(e);
    }
  }

  /// Upload a new logo, then save its URL on the shop.
  Future<String?> updateLogo(File file) async {
    final previous = state;
    state = state.copyWith(logoImage: file); // instant preview

    try {
      final url = await _api.uploadShopImage(file);
      final withUrl = state.copyWith(logoUrl: url);
      await _push(withUrl);
      if (mounted) state = withUrl;
      return null;
    } catch (e) {
      if (mounted) state = previous;
      return _msg(e);
    }
  }

  Future<String?> removeLogo() async {
    final previous = state;
    final next = state.copyWith(clearLogo: true);
    state = next;

    try {
      await _push(next); // image: null
      return null;
    } catch (e) {
      if (mounted) state = previous;
      return _msg(e);
    }
  }
}

String _orNotSet(String? v) => (v == null || v.isEmpty) ? 'Not set' : v;

// autoDispose: leaving the seller area (e.g. logout) clears this, so the
// next owner never sees the previous owner's store.
final sellerStoreProvider =
    StateNotifierProvider.autoDispose<SellerStoreNotifier, SellerStore>((ref) {
  final shop = ref.watch(myShopProvider).value;
  final api = ref.watch(shopApiServiceProvider);

  return SellerStoreNotifier(
    api,
    SellerStore(
      name: shop?.name ?? '',
      description: shop?.description ?? '',
      contactEmail: _orNotSet(shop?.contactEmail),
      returnPolicy: _orNotSet(shop?.returnPolicy),
      address: _orNotSet(shop?.address),
      contactPhone: _orNotSet(shop?.contactPhone),
      logoUrl: shop?.image,
    ),
  );
});