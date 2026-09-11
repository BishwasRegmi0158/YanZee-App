import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_config.dart';

class SellerApiService {
  static const _timeout = Duration(seconds: 10);

  Future<List<dynamic>> fetchMyProducts({int limit = 5, int skip = 0}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products')
        .replace(queryParameters: {'limit': '$limit', 'skip': '$skip'});
    final response = await http.get(url).timeout(_timeout);
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['products'] as List<dynamic>;
    }
    throw Exception('Failed to load products (${response.statusCode})');
  }

  Future<List<dynamic>> fetchCarts({int limit = 6}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/carts')
        .replace(queryParameters: {'limit': '$limit'});
    final response = await http.get(url).timeout(_timeout);
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['carts'] as List<dynamic>;
    }
    throw Exception('Failed to load carts (${response.statusCode})');
  }

  Future<Map<String, dynamic>> fetchUser(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/users/$id');
    final response = await http.get(url).timeout(_timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load user $id (${response.statusCode})');
  }
}