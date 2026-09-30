// features/seller/providers/seller_products_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_repository_provider.dart';

class SellerProductsNotifier extends AsyncNotifier<List<SellerProduct>> {
  int _localCounter = 0; // for temporary ids of newly-added products

  @override
  Future<List<SellerProduct>> build() {
    return ref.watch(sellerRepositoryProvider).getProducts();
  }

  void addProduct(SellerProduct draft) {
    final current = state.asData?.value ?? [];
    state = AsyncData([draft, ...current]);
  }

  void updateProduct(SellerProduct updated) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData([for (final p in current) p.id == updated.id ? updated : p]);
  }

  void deleteProduct(String id) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.where((p) => p.id != id).toList());
  }

  /// Temporary local id until the backend returns the real UUID.
  String newId() => 'local-${_localCounter++}-${DateTime.now().microsecondsSinceEpoch}';
}

final sellerProductsProvider =
    AsyncNotifierProvider<SellerProductsNotifier, List<SellerProduct>>(SellerProductsNotifier.new);