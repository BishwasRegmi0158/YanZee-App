import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/public_shop.dart';

class PublicShopPage {
  final List<PublicShop> shops;
  final int page;
  final int totalPages;
  const PublicShopPage({
    required this.shops,
    required this.page,
    required this.totalPages,
  });
  bool get hasMore => page < totalPages;
}

class PublicShopApiService {
  static const _timeout = Duration(seconds: 20);

  /// GET /shops?page=&limit=
  Future<PublicShopPage> fetchShops({int page = 1, int limit = 10}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops')
        .replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final res = await http.get(url).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to load shops (${res.statusCode})');
    }
    final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>? ??
        const {};
    final list = (data['shops'] as List?) ?? const [];
    final p = (data['pagination'] as Map?) ?? const {};
    return PublicShopPage(
      shops: list
          .whereType<Map<String, dynamic>>()
          .map(PublicShop.fromJson)
          .toList(),
      page: (p['page'] as num?)?.toInt() ?? page,
      totalPages: (p['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  /// GET /shops/:id
  Future<PublicShop> fetchShop(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops/$id');
    final res = await http.get(url).timeout(_timeout);
    if (res.statusCode == 404) throw Exception('Shop not found');
    if (res.statusCode != 200) {
      throw Exception('Failed to load shop (${res.statusCode})');
    }
    final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return PublicShop.fromJson(data['shop'] as Map<String, dynamic>);
  }
}