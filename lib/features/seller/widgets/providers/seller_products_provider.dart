import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/services/seller_product_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_repository_provider.dart';

final sellerProductApiProvider = Provider((ref) => SellerProductApiService());

class SellerProductsNotifier extends AsyncNotifier<List<SellerProduct>> {
  @override
  Future<List<SellerProduct>> build() {
    return ref.watch(sellerRepositoryProvider).getProducts();
  }

  SellerProductApiService get _api => ref.read(sellerProductApiProvider);

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  /// Re-reads the list from the server so new products get their real ids.
  Future<void> _reload() async {
    try {
      final fresh = await ref.read(sellerRepositoryProvider).getProducts();
      state = AsyncData(fresh);
    } catch (_) {
      // The save itself worked; keep showing the old list.
    }
  }

  /// POST /products. Returns null on success, or an error message.
  Future<String?> addProduct(SellerProduct draft, {File? image}) async {
    try {
      var product = draft;
      if (image != null) {
        final url = await _api.uploadCoverImage(image);
        product = product.copyWith(imageUrl: url);
      }
      await _api.createProduct(product.toApiJson());
    } catch (e) {
      return _msg(e);
    }
    await _reload();
    return null;
  }

  /// PATCH /products/:id. Returns null on success, or an error message.
  Future<String?> updateProduct(SellerProduct updated, {File? image}) async {
    try {
      var product = updated;
      if (image != null) {
        final url = await _api.uploadCoverImage(image);
        product = product.copyWith(imageUrl: url);
      }
      await _api.updateProduct(product.id, product.toApiJson());
    } catch (e) {
      return _msg(e);
    }
    await _reload();
    return null;
  }

  /// DELETE /products/:id. Removes it from the list at once and puts it back
  /// if the server refuses. Returns null on success, or an error message.
  Future<String?> deleteProduct(String id) async {
    final previous = state.asData?.value;
    if (previous != null) {
      state = AsyncData(previous.where((p) => p.id != id).toList());
    }
    try {
      await _api.deleteProduct(id);
      return null;
    } catch (e) {
      if (previous != null) state = AsyncData(previous);
      return _msg(e);
    }
  }
}

final sellerProductsProvider =
    AsyncNotifierProvider<SellerProductsNotifier, List<SellerProduct>>(
        SellerProductsNotifier.new);