import 'dart:convert';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/store_order.dart';

final storeOrderApiServiceProvider = Provider((ref) => StoreOrderApiService());

class StoreOrderPage {
  final List<StoreOrderRow> orders;
  final int page;
  final int totalPages;
  final int total;

  const StoreOrderPage({
    required this.orders,
    required this.page,
    required this.totalPages,
    required this.total,
  });
}

class StoreOrderApiService {
  Uri _url([String path = '', Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}/orders$path').replace(
        queryParameters: (query == null || query.isEmpty) ? null : query,
      );

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

  /// GET /orders?page=&limit=&search=&status=&channel=&from=&to=
  Future<StoreOrderPage> getOrders(
    String storeId, {
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? channel,
    DateTimeRange? range,
  }) async {
    final res = await ApiClient.send(
      (h) => http.get(
        _url('', {
          'page': '$page',
          'limit': '$limit',
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (status != null && status.isNotEmpty) 'status': status,
          if (channel != null && channel.isNotEmpty) 'channel': channel,
          if (range != null) 'from': range.start.toUtc().toIso8601String(),
          if (range != null) 'to': range.end.toUtc().toIso8601String(),
        }),
        headers: _headers(h, storeId),
      ),
    );
    _ensureOk(res, 'Could not load orders');

    final data = _data(res);
    final list = data['orders'] as List? ?? const [];
    final orders = list
        .whereType<Map>()
        .map((e) => StoreOrderRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final p = data['pagination'];
    return StoreOrderPage(
      orders: orders,
      page: p is Map ? (p['page'] as num?)?.toInt() ?? page : page,
      totalPages: p is Map ? (p['totalPages'] as num?)?.toInt() ?? 1 : 1,
      total: p is Map ? (p['total'] as num?)?.toInt() ?? orders.length : orders.length,
    );
  }

  /// GET /orders/:id
  Future<StoreOrderDetail> getOrder(String storeId, String id) async {
    final res = await ApiClient.send(
      (h) => http.get(_url('/$id'), headers: _headers(h, storeId)),
    );
    _ensureOk(res, 'Could not load the order');
    final order = _data(res)['order'];
    if (order is! Map) throw Exception('Unexpected response from the server');
    return StoreOrderDetail.fromJson(Map<String, dynamic>.from(order));
  }

  /// POST /orders. [body] is built by the order form.
  Future<({String id, int orderNumber})> createOrder(
    String storeId,
    Map<String, dynamic> body,
  ) async {
    final res = await ApiClient.send(
      (h) => http.post(
        _url(),
        headers: _headers(h, storeId, json: true),
        body: jsonEncode(body),
      ),
    );
    _ensureOk(res, 'Could not create the order');
    final data = _data(res);
    return (
      id: data['id']?.toString() ?? '',
      orderNumber: (data['orderNumber'] as num?)?.toInt() ?? 0,
    );
  }

  /// PATCH /orders/:id/summary (items, delivery fee, discount, payment).
  Future<void> updateSummary(
    String storeId,
    String id,
    Map<String, dynamic> body,
  ) async {
    final res = await ApiClient.send(
      (h) => http.patch(
        _url('/$id/summary'),
        headers: _headers(h, storeId, json: true),
        body: jsonEncode(body),
      ),
    );
    _ensureOk(res, 'Could not update the order');
  }

  /// PATCH /orders/:id/customer (name, phone, address and notes).
  Future<void> updateCustomer(
    String storeId,
    String id,
    Map<String, dynamic> body,
  ) async {
    final res = await ApiClient.send(
      (h) => http.patch(
        _url('/$id/customer'),
        headers: _headers(h, storeId, json: true),
        body: jsonEncode(body),
      ),
    );
    _ensureOk(res, 'Could not update the customer details');
  }

  /// PATCH /orders/:id/status. Returns the server's message, for example
  /// "Order marked as processing". The server refuses a skipped step with an
  /// error message, which is thrown as an Exception.
  Future<String> updateStatus(
    String storeId,
    String id, {
    required String status,
    String? reason,
    bool markAsPaid = false,
    bool? restoreStock,
  }) async {
    final body = {
      'status': status,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (markAsPaid) 'markAsPaid': true,
      if (restoreStock != null) 'restoreStock': restoreStock,
    };
    final res = await ApiClient.send(
      (h) => http.patch(
        _url('/$id/status'),
        headers: _headers(h, storeId, json: true),
        body: jsonEncode(body),
      ),
    );
    _ensureOk(res, 'Could not change the status');
    return _message(res, 'Order updated');
  }

  // ---- helpers ----

  Map<String, dynamic> _data(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>?) ?? const {};
  }

  void _ensureOk(http.Response res, String failure) {
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_message(res, '$failure (${res.statusCode})'));
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
    return fallback;
  }
}