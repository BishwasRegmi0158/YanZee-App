import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/seller_models.dart';

const _imageField = 'image';

class SellerProductApiService {
  Map<String, String> _json(Map<String, String> h) => {
        ...h,
        'Content-Type': 'application/json',
      };
  /// GET /products (owner list). Reads every page.
  /// [categoryId] is sent as ?categoryId=... when a category filter is set.
  Future<List<SellerProduct>> listProducts({String? categoryId}) async {
    final all = <SellerProduct>[];
    var page = 1;
    var totalPages = 1;

    do {
      final url = Uri.parse('${ApiConfig.baseUrl}/products').replace(
        queryParameters: {
          'page': '$page',
          'limit': '20',
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
        },
      );
      final res = await ApiClient.send((h) => http.get(url, headers: h));

      // Owner has no shop yet: an empty catalogue, not an error.
      if (res.statusCode == 404 && res.body.contains('do not have a shop')) {
        return const [];
      }
      if (res.statusCode != 200) {
        throw Exception(_message(res, 'Failed to load products'));
      }

      final data = _data(res);
      final items = (data['products'] as List?) ?? const [];
      all.addAll(
        items
            .whereType<Map>()
            .map((e) => SellerProduct.fromJson(Map<String, dynamic>.from(e))),
      );

      final pagination = data['pagination'];
      totalPages = pagination is Map
          ? (pagination['totalPages'] as num?)?.toInt() ?? 1
          : 1;
      page++;
    } while (page <= totalPages && page <= 50);

    return all;
  }

  /// GET /products/:id (the full product).
  Future<SellerProduct> getProduct(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/$id');
    final res = await ApiClient.send((h) => http.get(url, headers: h));
    if (res.statusCode != 200) {
      throw Exception(_message(res, 'Could not load product'));
    }
    final product = _data(res)['product'];
    if (product is! Map) throw Exception('Unexpected response from server');
    return SellerProduct.fromJson(Map<String, dynamic>.from(product));
  }

  /// POST /products. Returns the new product id.
  Future<String> createProduct(Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products');
    final res = await ApiClient.send(
      (h) => http.post(url, headers: _json(h), body: jsonEncode(body)),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_message(res, 'Could not create product'));
    }
    final product = _data(res)['product'];
    final id = product is Map ? product['id']?.toString() : null;
    if (id == null || id.isEmpty) {
      throw Exception('Unexpected response from server');
    }
    return id;
  }

  Future<void> updateGeneral(String id, Map<String, dynamic> body) =>
      _patch(id, 'general', body, 'Could not update product details');

  Future<void> updateInventory(String id, Map<String, dynamic> body) =>
      _patch(id, 'inventory', body, 'Could not update inventory');

  Future<void> updateStatus(String id, ProductStatus status) => _patch(
        id,
        'status',
        {'status': status.apiValue},
        'Could not change the status',
      );

  Future<void> updateCustom(String id, Map<String, dynamic> body) =>
      _patch(id, 'custom', body, 'Could not update product info');

  Future<void> updateSeo(String id, Map<String, dynamic> body) =>
      _patch(id, 'seo', body, 'Could not update SEO');

  /// DELETE /products/:id
  Future<void> deleteProduct(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/$id');
    final res = await ApiClient.send((h) => http.delete(url, headers: h));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_message(res, 'Could not delete product'));
    }
  }

  /// POST /images/products, returns the image URL.
  Future<String> uploadProductImage(File file) =>
      _upload('/images/products', file);

  /// POST /images/product-seo, returns the image URL.
  Future<String> uploadSeoImage(File file) =>
      _upload('/images/product-seo', file);

  // ---------- helpers ----------

  Future<void> _patch(
    String id,
    String section,
    Map<String, dynamic> body,
    String fallback,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/$id/$section');
    final res = await ApiClient.send(
      (h) => http.patch(url, headers: _json(h), body: jsonEncode(body)),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_message(res, fallback));
    }
  }

  Future<String> _upload(String path, File file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final res = await ApiClient.send((h) async {
      // Built fresh on every call: ApiClient may retry after a token refresh.
      final req = http.MultipartRequest('POST', url)
        ..headers.addAll(h)
        ..headers.remove('Content-Type')
        ..files.add(await http.MultipartFile.fromPath(_imageField, file.path));
      return http.Response.fromStream(await req.send());
    });
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_message(res, 'Image upload failed'));
    }
    final imageUrl = _data(res)['url']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception('Unexpected response from server');
    }
    return imageUrl;
  }

  /// Unwraps {success, statusCode, message, data}.
  Map<String, dynamic> _data(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw Exception('Unexpected response from server');
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