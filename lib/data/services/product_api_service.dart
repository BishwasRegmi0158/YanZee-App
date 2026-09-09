import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api/api_config.dart';

class ProductApiService {
  static const _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> fetchProductsPage({
    int limit = 20,
    int skip = 0,
    String? sortBy,
    String? order,
  }) async {
    final queryParams = {
      'limit': '$limit',
      'skip': '$skip',
      if (sortBy != null) 'sortBy': sortBy,
      if (order != null) 'order': order,
    };
    final url = Uri.parse('${ApiConfig.baseUrl}/products')
        .replace(queryParameters: queryParams);
    final response = await http.get(url).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load products (${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> fetchProductsByCategoryPage({
    required String categorySlug,
    int limit = 20,
    int skip = 0,
    String? sortBy,
    String? order,
  }) async {
    final queryParams = {
      'limit': '$limit',
      'skip': '$skip',
      if (sortBy != null) 'sortBy': sortBy,
      if (order != null) 'order': order,
    };
    final url = Uri.parse('${ApiConfig.baseUrl}/products/category/$categorySlug')
        .replace(queryParameters: queryParams);
    final response = await http.get(url).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load category products (${response.statusCode})');
    }
  }

  Future<List<dynamic>> fetchProducts({int limit = 10}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products?limit=$limit');
    final response = await http.get(url).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['products'] as List<dynamic>;
    } else {
      throw Exception('Failed to load products (${response.statusCode})');
    }
  }

  Future<List<dynamic>> fetchProductsByCategory(String categorySlug) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/category/$categorySlug');
    final response = await http.get(url).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['products'] as List<dynamic>;
    } else {
      throw Exception('Failed to load category products (${response.statusCode})');
    }
  }

  Future<List<dynamic>> searchProducts(String query) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/search?q=$query');
    final response = await http.get(url).timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['products'] as List<dynamic>;
    } else {
      throw Exception('Search failed (${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> fetchProductById(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/$id');
    final response = await http.get(url).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load product $id (${response.statusCode})');
    }
  }
}