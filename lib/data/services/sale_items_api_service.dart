import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/sale_item.dart';

final saleItemsApiServiceProvider = Provider((ref) => SaleItemsApiService());

class SalePage {
  final List<SaleItem> items;
  final int page;
  final int totalPages;

  const SalePage({
    required this.items,
    required this.page,
    required this.totalPages,
  });
}

/// Staff-side call: needs a login and the store id. [channel] is POS or ADMIN.
class SaleItemsApiService {
  Future<SalePage> fetch(
    String storeId, {
    required String channel,
    String? outletId,
    String? search,
    bool includeOutOfStock = false,
    int page = 1,
    int limit = 20,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/sellable-items')
        .replace(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      'channel': channel,
      if (outletId != null && outletId.isNotEmpty) 'outletId': outletId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'includeOutOfStock': '$includeOutOfStock',
    });

    final res = await ApiClient.send(
      (h) => http.get(url, headers: {...h, 'x-store-id': storeId}),
    );
    if (res.statusCode != 200) {
      throw Exception(_message(res, 'Could not load products (${res.statusCode})'));
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final list = (data['items'] as List?) ?? const [];
    final p = data['pagination'];

    return SalePage(
      items: list
          .whereType<Map>()
          .map((e) => SaleItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      page: p is Map ? (p['page'] as num?)?.toInt() ?? page : page,
      totalPages: p is Map ? (p['totalPages'] as num?)?.toInt() ?? 1 : 1,
    );
  }

  String _message(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        final msg = body['message'] ?? body['error'];
        if (msg is List) return msg.join(', ');
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return fallback;
  }
}