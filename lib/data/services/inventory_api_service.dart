import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/inventory.dart';

final inventoryApiServiceProvider = Provider((ref) => InventoryApiService());

class InventoryApiService {
  Uri _url(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}/inventory$path')
          .replace(queryParameters: query);

  Map<String, String> _headers(
    Map<String, String> h,
    String storeId, {
    bool json = false,
  }) =>
      {
        ...h,
        'x-store-id': storeId,
        if (json) 'Content-Type': 'application/json',
      };

  /// GET /inventory/stock (every page).
  Future<List<StockItem>> getStock(String storeId) =>
      _getAll(storeId, '/stock', 'items', StockItem.fromJson);

  /// GET /inventory/movements (every page), optionally within a date range.
  Future<List<StockMovement>> getMovements(
    String storeId, {
    DateTime? from,
    DateTime? to,
  }) =>
      _getAll(
        storeId,
        '/movements',
        'movements',
        StockMovement.fromJson,
        {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      );

  /// POST /inventory/stock-in. Empty optional header fields are left out.
  Future<void> stockIn(
    String storeId, {
    required String outletId,
    String? referenceNumber,
    String? supplierName,
    String? note,
    required List<StockInLine> items,
  }) async {
    final body = {
      'outletId': outletId,
      if (referenceNumber != null) 'referenceNumber': referenceNumber,
      if (supplierName != null) 'supplierName': supplierName,
      if (note != null) 'note': note,
      'items': [for (final l in items) l.toJson()],
    };
    final res = await ApiClient.send(
      (h) => http.post(
        _url('/stock-in'),
        headers: _headers(h, storeId, json: true),
        body: jsonEncode(body),
      ),
    );
    _ensureOk(res, 'Could not add stock');
  }

  // ---- helpers ----

  Future<List<T>> _getAll<T>(
    String storeId,
    String path,
    String listKey,
    T Function(Map<String, dynamic>) parse, [
    Map<String, String> extra = const {},
  ]) async {
    final all = <T>[];
    var page = 1;
    var totalPages = 1;

    do {
      final res = await ApiClient.send(
        (h) => http.get(
          _url(path, {...extra, 'page': '$page', 'limit': '20'}),
          headers: _headers(h, storeId),
        ),
      );
      _ensureOk(res, 'Could not load inventory');

      final data = _data(res);
      final list = data[listKey] as List? ?? const [];
      all.addAll(list.whereType<Map<String, dynamic>>().map(parse));

      final pagination = data['pagination'];
      totalPages = pagination is Map
          ? (pagination['totalPages'] as num?)?.toInt() ?? 1
          : 1;
      page++;
    } while (page <= totalPages && page <= 50);

    return all;
  }

  Map<String, dynamic> _data(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>?) ?? const {};
  }

  void _ensureOk(http.Response res, String failure) {
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_message(res, failure));
    }
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
    return '$fallback (${res.statusCode})';
  }
}