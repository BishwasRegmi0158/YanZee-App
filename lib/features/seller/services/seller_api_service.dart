import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';

class SellerApiService {
  Future<List<dynamic>> fetchMyProducts() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products');
    final res = await ApiClient.send((h) => http.get(url, headers: h));
    debugPrint('PRODUCTS ${res.statusCode} ${res.body}');

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load products (${res.statusCode}): ${res.body}',
      );
    }
    // Owner has no shop yet: treat as an empty catalogue instead of an error.
    if (res.statusCode == 404 && res.body.contains('do not have a shop')) {
      return const [];
    }
    return _extractList(jsonDecode(res.body));
  }

  // The response wrapper isn't confirmed yet, so accept a bare list,
  // {data: [...]}, or {data: {products/items/results: [...]}}.
  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final data = body['data'] ?? body;
      if (data is List) return data;
      if (data is Map) {
        for (final key in ['products', 'items', 'results']) {
          if (data[key] is List) return data[key] as List;
        }
      }
    }
    return const [];
  }
}
