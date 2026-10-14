import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/outlet.dart';

final outletApiServiceProvider = Provider((ref) => OutletApiService());

class OutletApiService {
  Uri _url([String path = '', Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}/outlets$path')
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

  /// GET /outlets. The API is paginated (20 per page), so this walks every
  /// page and returns the full list.
  Future<List<Outlet>> getOutlets(String storeId) async {
    final all = <Outlet>[];
    var page = 1;
    var totalPages = 1;

    do {
      final res = await ApiClient.send(
        (h) => http.get(
          _url('', {'page': '$page', 'limit': '20'}),
          headers: _headers(h, storeId),
        ),
      );
      _ensureOk(res, 'Could not load outlets');

      final data = _data(res);
      final list = data['outlets'] as List? ?? const [];
      all.addAll(
        list.whereType<Map<String, dynamic>>().map(Outlet.fromJson),
      );

      final pagination = data['pagination'];
      totalPages = pagination is Map
          ? (pagination['totalPages'] as num?)?.toInt() ?? 1
          : 1;
      page++;
    } while (page <= totalPages && page <= 50);

    return all;
  }

  /// POST /outlets. Empty optional fields are left out of the body.
  Future<void> createOutlet(
    String storeId, {
    required String name,
    required String address,
    String? contactPerson,
    String? contactPhone,
  }) async {
    final body = {
      'name': name,
      'address': address,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (contactPhone != null) 'contactPhone': contactPhone,
    };
    final res = await ApiClient.send(
      (h) => http.post(
        _url(),
        headers: _headers(h, storeId, json: true),
        body: jsonEncode(body),
      ),
    );
    _ensureOk(res, 'Could not create outlet');
  }

  /// PATCH /outlets/:id. Contact fields are sent as null to clear them.
  Future<void> updateOutlet(
    String storeId,
    String id, {
    required String name,
    required String address,
    String? contactPerson,
    String? contactPhone,
  }) async {
    final body = {
      'name': name,
      'address': address,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
    };
    final res = await ApiClient.send(
      (h) => http.patch(
        _url('/$id'),
        headers: _headers(h, storeId, json: true),
        body: jsonEncode(body),
      ),
    );
    _ensureOk(res, 'Could not update outlet');
  }

  /// PATCH /outlets/:id/toggle-status. Returns the new isActive value.
  Future<bool> toggleStatus(String storeId, String id) async {
    final res = await ApiClient.send(
      (h) => http.patch(
        _url('/$id/toggle-status'),
        headers: _headers(h, storeId),
      ),
    );
    _ensureOk(res, 'Could not change outlet status');
    final outlet = _data(res)['outlet'];
    return outlet is Map ? outlet['isActive'] == true : false;
  }

  /// DELETE /outlets/:id
  Future<void> deleteOutlet(String storeId, String id) async {
    final res = await ApiClient.send(
      (h) => http.delete(_url('/$id'), headers: _headers(h, storeId)),
    );
    _ensureOk(res, 'Could not delete outlet');
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
      final msg = body is Map ? body['message'] : null;
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return fallback;
  }
}