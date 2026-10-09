import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/shop_category.dart';
import 'package:yanzee_app/data/services/category_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

class SellerCategoriesNotifier extends AsyncNotifier<List<ShopCategory>> {
  @override
  Future<List<ShopCategory>> build() async {
    // Runs again when the selected shop changes.
    final shop = await ref.watch(myShopProvider.future);
    if (shop == null) return const [];
    return ref.watch(categoryApiServiceProvider).getCategories(shop.id);
  }

  CategoryApiService get _api => ref.read(categoryApiServiceProvider);
  String? get _storeId => ref.read(myShopProvider).value?.id;

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _reload(String storeId) async {
    try {
      state = AsyncData(await _api.getCategories(storeId));
    } catch (_) {
      // The save worked; keep showing the old list.
    }
  }

  /// Returns null on success, or an error message.
  Future<String?> create({
    required String name,
    required bool isAvailable,
    File? image,
    String? description,
  }) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    try {
      String? url;
      if (image != null) url = await _api.uploadCategoryImage(storeId, image);
      await _api.createCategory(
        storeId,
        name: name,
        isAvailable: isAvailable,
        image: url,
        description: description,
      );
    } catch (e) {
      return _msg(e);
    }
    await _reload(storeId);
    return null;
  }

  /// Returns null on success, or an error message.

  Future<String?> updateCategory(
    ShopCategory category, {
    required String name,
    required bool isAvailable,
    File? image,
    String? description,
  }) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    try {
      String? url;
      if (image != null) url = await _api.uploadCategoryImage(storeId, image);
      await _api.updateCategory(
        storeId,
        category.id,
        name: name,
        image: url,
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
  Future<String?> toggle(ShopCategory category) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    final previous = state.asData?.value;
    if (previous == null) return null;

    state = AsyncData([
      for (final c in previous)
        c.id == category.id ? c.copyWith(isAvailable: !c.isAvailable) : c,
    ]);
    try {
      final now = await _api.toggleAvailability(storeId, category.id);
      final current = state.asData?.value ?? previous;
      state = AsyncData([
        for (final c in current)
          c.id == category.id ? c.copyWith(isAvailable: now) : c,
      ]);
      return null;
    } catch (e) {
      state = AsyncData(previous);
      return _msg(e);
    }
  }

  /// Removes it at once, puts it back if the server refuses.
  Future<String?> delete(ShopCategory category) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    final previous = state.asData?.value;
    if (previous != null) {
      state = AsyncData(previous.where((c) => c.id != category.id).toList());
    }
    try {
      await _api.deleteCategory(storeId, category.id);
      return null;
    } catch (e) {
      if (previous != null) state = AsyncData(previous);
      return _msg(e);
    }
  }
}

final sellerCategoriesProvider = AsyncNotifierProvider.autoDispose<
    SellerCategoriesNotifier, List<ShopCategory>>(SellerCategoriesNotifier.new);