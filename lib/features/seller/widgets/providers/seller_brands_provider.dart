import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/brand.dart';
import 'package:yanzee_app/data/services/brand_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

final brandApiServiceProvider = Provider((ref) => BrandApiService());

class SellerBrandsNotifier extends AsyncNotifier<List<Brand>> {
  @override
  Future<List<Brand>> build() async {
    // Runs again whenever the selected shop changes, so each shop
    // shows its own brands.
    final shop = await ref.watch(myShopProvider.future);
    if (shop == null) return const [];
    return ref.watch(brandApiServiceProvider).getBrands(shop.id);
  }

  BrandApiService get _api => ref.read(brandApiServiceProvider);
  String? get _storeId => ref.read(myShopProvider).value?.id;

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _reload(String storeId) async {
    try {
      state = AsyncData(await _api.getBrands(storeId));
    } catch (_) {
      // The save worked; keep showing the old list.
    }
  }

  /// Returns null on success, or an error message.
  Future<String?> createBrand({
    required String name,
    required bool isAvailable,
    File? logo,
    String? description,
  }) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    try {
      String? logoUrl;
      if (logo != null) logoUrl = await _api.uploadBrandLogo(storeId, logo);
      await _api.createBrand(
        storeId,
        name: name,
        isAvailable: isAvailable,
        logo: logoUrl,
        description: description,
      );
    } catch (e) {
      return _msg(e);
    }
    await _reload(storeId);
    return null;
  }

  /// Returns null on success, or an error message.
  Future<String?> updateBrand(
    Brand brand, {
    required String name,
    required bool isAvailable,
    File? logo,
    String? description,
  }) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    try {
      String? logoUrl;
      if (logo != null) logoUrl = await _api.uploadBrandLogo(storeId, logo);
      await _api.updateBrand(
        storeId,
        brand.id,
        name: name,
        logo: logoUrl,
        description: description,
        isAvailable: isAvailable,
      );
    } catch (e) {
      return _msg(e);
    }
    await _reload(storeId);
    return null;
  }

  /// Flips the switch at once, puts it back if the server refuses.
  Future<String?> toggle(Brand brand) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    final previous = state.asData?.value;
    if (previous == null) return null;

    state = AsyncData([
      for (final b in previous)
        b.id == brand.id ? b.copyWith(isAvailable: !b.isAvailable) : b,
    ]);
    try {
      final now = await _api.toggleAvailability(storeId, brand.id);
      final current = state.asData?.value ?? previous;
      state = AsyncData([
        for (final b in current)
          b.id == brand.id ? b.copyWith(isAvailable: now) : b,
      ]);
      return null;
    } catch (e) {
      state = AsyncData(previous);
      return _msg(e);
    }
  }

  /// Removes it at once, puts it back if the server refuses.
  Future<String?> deleteBrand(Brand brand) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    final previous = state.asData?.value;
    if (previous != null) {
      state = AsyncData(previous.where((b) => b.id != brand.id).toList());
    }
    try {
      await _api.deleteBrand(storeId, brand.id);
      return null;
    } catch (e) {
      if (previous != null) state = AsyncData(previous);
      return _msg(e);
    }
  }
}

final sellerBrandsProvider =
    AsyncNotifierProvider.autoDispose<SellerBrandsNotifier, List<Brand>>(
  SellerBrandsNotifier.new,
);