import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/brand.dart';

// Multipart field name for POST /images/brands.
const _imageField = 'image';


const _toggleMethod = 'POST';

class BrandApiService {
  Uri get _brands => Uri.parse('${ApiConfig.baseUrl}/brands');

  Map<String, String> _withStore(Map<String, String> h, String storeId) => {
    ...h,
    'x-store-id': storeId,
  };

  Map<String, String> _json(Map<String, String> h, String storeId) => {
    ..._withStore(h, storeId),
    'Content-Type': 'application/json',
  };

  /// GET /brands?page=&limit=20. Loads every page so the owner sees all brands.
  Future<List<Brand>> getBrands(String storeId) async {
    final all = <Brand>[];
    var page = 1;
    while (true) {
      final url = _brands.replace(
        queryParameters: {'page': '$page', 'limit': '20'},
      );
      final res = await ApiClient.send(
        (h) => http.get(url, headers: _withStore(h, storeId)),
      );
      if (res.statusCode != 200) {
        throw Exception(
          _message(res, 'Failed to load brands (${res.statusCode})'),
        );
      }
      final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'];
      final list = data is Map ? data['brands'] : null;
      if (list is List) {
        all.addAll(
          list.whereType<Map>().map(
            (m) => Brand.fromJson(Map<String, dynamic>.from(m)),
          ),
        );
      }
      final pagination = data is Map ? data['pagination'] : null;
      final totalPages = pagination is Map
          ? (pagination['totalPages'] as num?)?.toInt() ?? 1
          : 1;
      if (page >= totalPages || page >= 50) break;
      page++;
    }
    return all;
  }

  /// POST /images/brands. Returns the uploaded image URL.
  Future<String> uploadBrandLogo(String storeId, File file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/images/brands');
    final res = await ApiClient.send((h) async {
      // Built fresh on every call: ApiClient may retry after a token refresh.
      final req = http.MultipartRequest('POST', url)
        ..headers.addAll(_withStore(h, storeId))
        ..headers.remove('Content-Type') // let multipart set its boundary
        ..files.add(await http.MultipartFile.fromPath(_imageField, file.path));
      return http.Response.fromStream(await req.send());
    });

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_message(res, 'Image upload failed (${res.statusCode})'));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>)['url'] as String;
  }

  /// POST /brands
  Future<void> createBrand(
    String storeId, {
    required String name,
    required bool isAvailable,
    String? logo,
    String? description,
  }) async {
    final res = await ApiClient.send(
      (h) => http.post(
        _brands,
        headers: _json(h, storeId),
        body: jsonEncode({
          'name': name,
          'isAvailable': isAvailable,
          if (logo != null) 'logo': logo,
          if (description != null) 'description': description,
        }),
      ),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not create brand (${res.statusCode})'),
      );
    }
  }

  /// PATCH /brands/:id. Only the fields you pass are sent.
  Future<void> updateBrand(
    String storeId,
    String id, {
    String? name,
    String? logo,
    String? description,
    bool? isAvailable,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/brands/$id');
    final res = await ApiClient.send(
      (h) => http.patch(
        url,
        headers: _json(h, storeId),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (logo != null) 'logo': logo,
          if (description != null) 'description': description,
          if (isAvailable != null) 'isAvailable': isAvailable,
        }),
      ),
    );
    if (res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not update brand (${res.statusCode})'),
      );
    }
  }

  /// .../brands/:id/toggle-availability. Returns the new isAvailable value.
  Future<bool> toggleAvailability(String storeId, String id) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/brands/$id/toggle-availability',
    );
    final res = await ApiClient.send((h) async {
      final req = http.Request(_toggleMethod, url)
        ..headers.addAll(_withStore(h, storeId));
      return http.Response.fromStream(await req.send());
    });
    if (res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not change availability (${res.statusCode})'),
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final brand = (body['data'] as Map<String, dynamic>)['brand'] as Map;
    return brand['isAvailable'] == true;
  }

  /// DELETE /brands/:id
  Future<void> deleteBrand(String storeId, String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/brands/$id');
    final res = await ApiClient.send(
      (h) => http.delete(url, headers: _withStore(h, storeId)),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        _message(res, 'Could not delete brand (${res.statusCode})'),
      );
    }
  }

  String _message(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      final msg = body is Map ? body['message'] : null;
      if (msg is List) return msg.join(', ');
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return fallback;
  }
}
