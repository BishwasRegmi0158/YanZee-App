import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/data/services/outlet_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

class SellerOutletsNotifier extends AsyncNotifier<List<Outlet>> {
  @override
  Future<List<Outlet>> build() async {
    // Runs again when the selected shop changes.
    final shop = await ref.watch(myShopProvider.future);
    if (shop == null) return const [];
    return ref.watch(outletApiServiceProvider).getOutlets(shop.id);
  }

  OutletApiService get _api => ref.read(outletApiServiceProvider);
  String? get _storeId => ref.read(myShopProvider).value?.id;

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _reload(String storeId) async {
    try {
      state = AsyncData(await _api.getOutlets(storeId));
    } catch (_) {
      // The save worked; keep showing the old list.
    }
  }

  /// Returns null on success, or an error message.
  Future<String?> create({
    required String name,
    required String address,
    String? contactPerson,
    String? contactPhone,
  }) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    try {
      await _api.createOutlet(
        storeId,
        name: name,
        address: address,
        contactPerson: contactPerson,
        contactPhone: contactPhone,
      );
    } catch (e) {
      return _msg(e);
    }
    // The create response only has id + name, so load the full list again.
    await _reload(storeId);
    return null;
  }

  /// Returns null on success, or an error message.
  Future<String?> updateOutlet(
    Outlet outlet, {
    required String name,
    required String address,
    String? contactPerson,
    String? contactPhone,
  }) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    try {
      await _api.updateOutlet(
        storeId,
        outlet.id,
        name: name,
        address: address,
        contactPerson: contactPerson,
        contactPhone: contactPhone,
      );
    } catch (e) {
      return _msg(e);
    }
    await _reload(storeId);
    return null;
  }

  /// Flips the switch at once, puts it back if the server refuses.
  Future<String?> toggle(Outlet outlet) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    final previous = state.asData?.value;
    if (previous == null) return null;

    state = AsyncData([
      for (final o in previous)
        o.id == outlet.id ? o.copyWith(isActive: !o.isActive) : o,
    ]);
    try {
      final now = await _api.toggleStatus(storeId, outlet.id);
      final current = state.asData?.value ?? previous;
      state = AsyncData([
        for (final o in current)
          o.id == outlet.id ? o.copyWith(isActive: now) : o,
      ]);
      return null;
    } catch (e) {
      state = AsyncData(previous);
      return _msg(e);
    }
  }

  /// Removes it at once, puts it back if the server refuses.
  Future<String?> delete(Outlet outlet) async {
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) return 'No store loaded.';
    final previous = state.asData?.value;
    if (previous != null) {
      state = AsyncData(previous.where((o) => o.id != outlet.id).toList());
    }
    try {
      await _api.deleteOutlet(storeId, outlet.id);
      return null;
    } catch (e) {
      if (previous != null) state = AsyncData(previous);
      return _msg(e);
    }
  }
}

final sellerOutletsProvider = AsyncNotifierProvider.autoDispose<
    SellerOutletsNotifier, List<Outlet>>(SellerOutletsNotifier.new);