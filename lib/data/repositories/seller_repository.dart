import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/services/seller_product_api_service.dart';

class SellerRepository {
  final SellerProductApiService _products = SellerProductApiService();

  Future<List<SellerProduct>> getAllProducts({String? categoryId}) =>
      _products.listProducts(categoryId: categoryId);

  // Orders endpoint path not wired yet, so return empty (dashboard shows zeros).
  Future<List<SellerOrder>> getAllOrders() async => const [];

  Future<List<SellerProduct>> getProducts({String? categoryId}) =>
      getAllProducts(categoryId: categoryId);
  Future<List<SellerOrder>> getOrders() => getAllOrders();
}