// lib/data/repositories/product_repository.dart
import 'package:yanzee_app/core/utils/parse.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/services/product_api_service.dart';

class ProductPage {
  final List<Product> products;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const ProductPage({
    required this.products,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}

class ProductRepository {
  final ProductApiService _api = ProductApiService();

  /// Paginated + filterable list. Used by the Shop screen and by every
  /// helper below.
  Future<ProductPage> getPublicProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category, // backend enum, null = all
    String? audience,
    double? minPrice,
    double? maxPrice,
  }) async {
    final data = await _api.fetchPublicProducts(
      page: page,
      limit: limit,
      search: search,
      category: category,
      audience: audience,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    final products = ((data['products'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
    final pagination =
        (data['pagination'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return ProductPage(
      products: products,
      page: parseInt(pagination['page'], page),
      limit: parseInt(pagination['limit'], limit),
      total: parseInt(pagination['total'], products.length),
      totalPages: parseInt(pagination['totalPages'], 1),
    );
  }

  /// Home "New Arrivals" (the backend's default order).
  Future<List<Product>> getNewArrivals({int limit = 10}) async =>
      (await getPublicProducts(limit: limit)).products;

  Future<List<Product>> getProductsByCategory(
    String category, {
    int limit = 50,
  }) async =>
      (await getPublicProducts(category: category.toUpperCase(), limit: limit))
          .products;

  Future<List<Product>> searchProducts(String query, {int limit = 30}) async =>
      (await getPublicProducts(search: query, limit: limit)).products;

  Future<Product> getProductById(String id) async {
    final data = await _api.fetchProductById(id);
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  /// The product API only returns shopId, so the shop name is looked up here.
  Future<String> getShopName(String shopId) async {
    final data = await _api.fetchShopById(shopId);
    final shop = data['shop'] as Map<String, dynamic>?;
    return (shop?['name'] ?? '').toString();
  }
}