import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/shop_category.dart';

// Multipart field name for POST /images/categories.
const _imageField = 'image';

final categoryApiServiceProvider = Provider((ref) => CategoryApiService());

class CategoryApiService {
  Uri get _categories => Uri.parse('${ApiConfig.baseUrl}/categories');

  Map<String, String> _withStore(Map<String, String> h, String storeId) => {
        ...h,
        'x-store-id': storeId,
      };

  Map<String, String> _json(Map<String, String> h, String storeId) => {
        ..._withStore(h, storeId),
        'Content-Type': 'application/json',
      };

  /// GET /categories?page=&limit=20. Loads every page.
  Future<List<ShopCategory>> getCategories(String storeId) async {
    final all = <ShopCategory>[];
    var page = 1;
    while (true) {
      final url = _categories.replace(
        queryParameters: {'page': '$page', 'limit': '20'},
      );
      final res = await ApiClient.send(
        (h) => http.get(url, headers: _withStore(h, storeId)),
      );
      if (res.statusCode != 200) {
        throw Exception(
          _message(res, 'Failed to load categories (${res.statusCode})'),
        );
      }
      final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'];
      final list = data is Map ? data['categories'] : null;
      if (list is List) {
        all.addAll(
          list.whereType<Map>().map(
                (m) => ShopCategory.fromJson(Map<String, dynamic>.from(m)),
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

  /// POST /images/categories. Returns the uploaded image URL.
  Future<String> uploadCategoryImage(String storeId, File file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/images/categories');
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

  /// POST /categories
  Future<void> createCategory(
    String storeId, {
    required String name,
    required bool isAvailable,
    String? image,
    String? description,
  }) async {
    final res = await ApiClient.send(
      (h) => http.post(
        _categories,
        headers: _json(h, storeId),
        body: jsonEncode({
          'name': name,
          'isAvailable': isAvailable,
          if (image != null) 'image': image,
          if (description != null) 'description': description,
        }),
      ),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not create category (${res.statusCode})'),
      );
    }
  }

  /// PATCH /categories/:id. Only the fields you pass are sent.
  Future<void> updateCategory(
    String storeId,
    String id, {
    String? name,
    String? image,
    String? description,
    bool? isAvailable,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/categories/$id');
    final res = await ApiClient.send(
      (h) => http.patch(
        url,
        headers: _json(h, storeId),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (image != null) 'image': image,
          if (description != null) 'description': description,
          if (isAvailable != null) 'isAvailable': isAvailable,
        }),
      ),
    );
    if (res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not update category (${res.statusCode})'),
      );
    }
  }

  /// POST /categories/:id/toggle-availability. Returns the new isAvailable.
  Future<bool> toggleAvailability(String storeId, String id) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/categories/$id/toggle-availability');
    final res = await ApiClient.send(
      (h) => http.post(url, headers: _withStore(h, storeId)),
    );
    if (res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not change availability (${res.statusCode})'),
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final category = (body['data'] as Map<String, dynamic>)['category'] as Map;
    return category['isAvailable'] == true;
  }

  /// DELETE /categories/:id
  Future<void> deleteCategory(String storeId, String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/categories/$id');
    final res = await ApiClient.send(
      (h) => http.delete(url, headers: _withStore(h, storeId)),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        _message(res, 'Could not delete category (${res.statusCode})'),
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