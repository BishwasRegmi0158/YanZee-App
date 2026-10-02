// lib/data/services/product_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_config.dart';

/// Customer-side (public) product + shop calls. No token needed.
class ProductApiService {
  // Render's free tier can take a while to wake up, so be generous.
  static const _timeout = Duration(seconds: 30);

  /// GET /products/public
  Future<Map<String, dynamic>> fetchPublicProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? audience,
    double? minPrice,
    double? maxPrice,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (audience != null && audience.isNotEmpty) 'audience': audience,
      if (minPrice != null) 'minPrice': _num(minPrice),
      if (maxPrice != null) 'maxPrice': _num(maxPrice),
    };
    final url = Uri.parse('${ApiConfig.baseUrl}/products/public')
        .replace(queryParameters: query);
    final response = await http.get(url).timeout(_timeout);
    return _data(response, 'Failed to load products');
  }

  /// GET /products/:id  (returns data.product with description)
  Future<Map<String, dynamic>> fetchProductById(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/$id');
    final response = await http.get(url).timeout(_timeout);
    return _data(response, 'Failed to load product');
  }

  /// GET /shops/:id  (returns data.shop)
  Future<Map<String, dynamic>> fetchShopById(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops/$id');
    final response = await http.get(url).timeout(_timeout);
    return _data(response, 'Failed to load shop');
  }

  String _num(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  /// Unwraps {success, statusCode, message, data}; throws with the
  /// backend's message on failure.
  Map<String, dynamic> _data(http.Response response, String fallback) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (body?['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    }
    final message = body?['message'] ?? fallback;
    throw Exception('$message (${response.statusCode})');
  }
}