import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/services/seller_api_service.dart';

class SellerRepository {
  final SellerApiService _api = SellerApiService();

  Future<List<SellerProduct>> getAllProducts() async {
    final raw = await _api.fetchMyProducts();
    return raw.map((e) => SellerProduct.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Orders endpoint path not wired yet, so return empty (dashboard shows zeros).
  Future<List<SellerOrder>> getAllOrders() async => const [];

  Future<List<SellerProduct>> getProducts() => getAllProducts();
  Future<List<SellerOrder>> getOrders() => getAllOrders();
}