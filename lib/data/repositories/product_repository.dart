import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/services/product_api_service.dart';

class ProductRepository {
  final ProductApiService _apiService = ProductApiService();

  Future<List<Product>> getNewArrivals({int limit = 10}) async {
  final rawList = await _apiService.fetchProducts(limit: limit);
  return rawList.map((json) => Product.fromJson(json)).toList();
}
  Future<List<Product>> getProductsByCategory(String categorySlug) async {
  final rawProducts = await _apiService.fetchProductsByCategory(categorySlug);
  return rawProducts.map((json) => Product.fromJson(json)).toList();
}
Future<List<Product>> searchProducts(String query) async {
  final rawList = await _apiService.searchProducts(query);
  return rawList.map((json) => Product.fromJson(json)).toList();
}
}
