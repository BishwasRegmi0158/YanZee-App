import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/customer.dart';

final customerApiServiceProvider = Provider((ref) => CustomerApiService());

typedef CustomerPage = ({List<Customer> items, int totalCount});

class CustomerApiService {
  Uri _url([String path = '', Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}/customers$path')
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

  /// GET /customers?page=&limit=&search=
  Future<CustomerPage> getCustomers(
    String storeId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final res = await ApiClient.send(
      (h) => http.get(
        _url('', {
          'page': '$page',
          'limit': '$limit',
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        }),
        headers: _headers(h, storeId),
      ),
    );
    _ensureOk(res, 'Could not load customers');

    final data = _data(res);
    final list = data['customers'] as List? ?? const [];
    final items =
        list.whereType<Map<String, dynamic>>().map(Customer.fromJson).toList();
    final pagination = data['pagination'];
    final total = pagination is Map
        ? (pagination['totalCount'] as num?)?.toInt() ?? items.length
        : items.length;
    return (items: items, totalCount: total);
  }

  /// POST /customers. Empty optional fields are left out of the body.
  Future<void> createCustomer(
    String storeId, {
    required String name,
    String? phone,
    String? email,
  }) async {
    final body = {
      'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    };
    final res = await ApiClient.send(
      (h) => http.post(
        _url(),
        headers: _headers(h, storeId, json: true),
        body: jsonEncode(body),
      ),
    );
    _ensureOk(res, 'Could not add customer');
  }

  /// PATCH /customers/:id with only the fields that changed.
  Future<void> updateCustomer(
    String storeId,
    String id,
    Map<String, dynamic> changes,
  ) async {
    final res = await ApiClient.send(
      (h) => http.patch(
        _url('/$id'),
        headers: _headers(h, storeId, json: true),
        body: jsonEncode(changes),
      ),
    );
    _ensureOk(res, 'Could not update customer');
  }

  /// DELETE /customers/:id
  Future<void> deleteCustomer(String storeId, String id) async {
    final res = await ApiClient.send(
      (h) => http.delete(_url('/$id'), headers: _headers(h, storeId)),
    );
    _ensureOk(res, 'Could not delete customer');
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