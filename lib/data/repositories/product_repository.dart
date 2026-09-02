import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/services/product_api_service.dart';

class ProductRepository {
  final ProductApiService _apiService = ProductApiService();

  Future<List<Product>> getNewArrivals() async {
    final rawList = await _apiService.fetchProducts(limit: 10);
    return rawList.map((json) => Product.fromJson(json)).toList();
  }
}
