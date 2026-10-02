import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/public_product.dart';

class PublicProductPage {
  final List<PublicProduct> products;
  final int page;
  final int totalPages;
  final int total;

  const PublicProductPage({
    required this.products,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  bool get hasMore => page < totalPages;
}

class PublicProductApiService {
  static const _timeout = Duration(seconds: 20);

  /// GET /products/public. [category] and [audience] must be backend enum
  /// values (e.g. SPORTS, HOME_DECOR / MEN, KIDS_UNISEX).
  Future<PublicProductPage> fetchPage({
    int page = 1,
    int limit = 10,
    String? search,
    String? category,
    String? audience,
    double? minPrice,
    double? maxPrice,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (audience != null && audience.isNotEmpty) 'audience': audience,
      if (minPrice != null) 'minPrice': '$minPrice',
      if (maxPrice != null) 'maxPrice': '$maxPrice',
    };
    final url = Uri.parse('${ApiConfig.baseUrl}/products/public')
        .replace(queryParameters: params);

    // Plain http.get on purpose: customers browse without logging in.
    final res = await http.get(url).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to load products (${res.statusCode})');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final list = (data['products'] as List?) ?? const [];
    final p = (data['pagination'] as Map?) ?? const {};

    return PublicProductPage(
      products: list
          .whereType<Map<String, dynamic>>()
          .map(PublicProduct.fromJson)
          .toList(),
      page: (p['page'] as num?)?.toInt() ?? page,
      totalPages: (p['totalPages'] as num?)?.toInt() ?? 1,
      total: (p['total'] as num?)?.toInt() ?? list.length,
    );
  }
}