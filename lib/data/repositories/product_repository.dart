import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/services/product_api_service.dart';

class ProductPage {
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  bool get hasMore => skip + products.length < total;
}

class ProductRepository {
  final ProductApiService _apiService = ProductApiService();

  /// Used by Home screen's New Arrivals section
  Future<List<Product>> getNewArrivals({int limit = 10}) async {
    final rawList = await _apiService.fetchProducts(limit: limit);
    return rawList.map((json) => Product.fromJson(json)).toList();
  }

  /// Used by Category Products screen
  Future<List<Product>> getProductsByCategory(String categorySlug) async {
    final rawProducts = await _apiService.fetchProductsByCategory(categorySlug);
    return rawProducts.map((json) => Product.fromJson(json)).toList();
  }

  /// Used by Search screen
  Future<List<Product>> searchProducts(String query) async {
    final rawList = await _apiService.searchProducts(query);
    return rawList.map((json) => Product.fromJson(json)).toList();
  }

  // fetch the product through id
Future<Product> getProductById(int id) async {
  final json = await _apiService.fetchProductById(id);
  return Product.fromJson(json);
}

  /// Used by Shop screen — paginated, filterable, sortable
  Future<ProductPage> getProducts({
    int limit = 20,
    int skip = 0,
    String? category, // null or 'all' means no category filter
    String? sortBy,
    String? order,
  }) async {
    final json = (category == null || category == 'all')
        ? await _apiService.fetchProductsPage(
            limit: limit, skip: skip, sortBy: sortBy, order: order)
        : await _apiService.fetchProductsByCategoryPage(
            categorySlug: category,
            limit: limit,
            skip: skip,
            sortBy: sortBy,
            order: order,
          );

    return ProductPage(
      products: (json['products'] as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      skip: json['skip'] as int,
      limit: json['limit'] as int,
    );
  }
}