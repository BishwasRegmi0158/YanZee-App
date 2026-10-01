import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/seller_models.dart';

class SellerApiService {
  static const String _imageField = 'image'; // assumed multipart key

  Future<List<dynamic>> fetchMyProducts() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products');
    final res = await ApiClient.send((h) => http.get(url, headers: h));
    debugPrint('PRODUCTS ${res.statusCode} ${res.body}');

    // Owner has no shop yet: treat as an empty catalogue instead of an error.
    if (res.statusCode == 404 && res.body.contains('do not have a shop')) {
      return const [];
    }
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Failed to load products'));
    }
    return _extractList(jsonDecode(res.body));
  }

  /// POST /products. Always multipart so the cover image can be attached.
  Future<Map<String, dynamic>> createProduct(
    SellerProduct product, {
    File? image,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products');
    final res = await ApiClient.send(
      (h) => _sendMultipart('POST', url, h, product, image),
    );
    debugPrint('CREATE ${res.statusCode} ${res.body}');

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errorMessage(res, 'Could not create product'));
    }
    return _extractObject(jsonDecode(res.body));
  }

  /// PATCH /products/:id. Multipart if a new image was picked, JSON otherwise.
  Future<Map<String, dynamic>> updateProduct(
    SellerProduct product, {
    File? image,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/${product.id}');
    final res = await ApiClient.send((h) {
      if (image != null) {
        return _sendMultipart('PATCH', url, h, product, image);
      }
      return http.patch(
        url,
        headers: {...h, 'Content-Type': 'application/json'},
        body: jsonEncode(product.toApiJson()),
      );
    });
    debugPrint('UPDATE ${res.statusCode} ${res.body}');

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errorMessage(res, 'Could not update product'));
    }
    return _extractObject(jsonDecode(res.body));
  }

  /// DELETE /products/:id
  Future<void> deleteProduct(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/$id');
    final res = await ApiClient.send((h) => http.delete(url, headers: h));
    debugPrint('DELETE ${res.statusCode} ${res.body}');

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errorMessage(res, 'Could not delete product'));
    }
  }

  // ---------- helpers ----------

  Future<http.Response> _sendMultipart(
    String method,
    Uri url,
    Map<String, String> headers,
    SellerProduct p,
    File? image,
  ) async {
    final req = http.MultipartRequest(method, url);
    // Let http set the multipart Content-Type (with its boundary).
    req.headers.addAll({
      for (final e in headers.entries)
        if (e.key.toLowerCase() != 'content-type') e.key: e.value,
    });

    req.fields['name'] = p.name;
    req.fields['category'] = categoryToApi(p.category);
    req.fields['audience'] = p.audience.apiValue;
    req.fields['status'] = p.status.apiValue;
    req.fields['price'] = p.price.toString();
    if (p.discountPrice != null) {
      req.fields['discountPrice'] = p.discountPrice.toString();
    }
    req.fields['description'] = p.description;
    req.fields['variants'] = jsonEncode(
      p.variants.map((v) => v.toJson()).toList(),
    );

    if (image != null) {
      req.files.add(await http.MultipartFile.fromPath(_imageField, image.path));
    }
    return http.Response.fromStream(await req.send());
  }

  String _errorMessage(http.Response res, String fallback) {
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

  Map<String, dynamic> _extractObject(dynamic body) {
    if (body is Map) {
      final data = body['data'] ?? body;
      if (data is Map) {
        final inner = data['product'];
        if (inner is Map) return Map<String, dynamic>.from(inner);
        return Map<String, dynamic>.from(data);
      }
    }
    throw Exception('Unexpected response from server');
  }

  // The response wrapper isn't confirmed yet, so accept a bare list,
  // {data: [...]}, or {data: {products/items/results: [...]}}.
  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final data = body['data'] ?? body;
      if (data is List) return data;
      if (data is Map) {
        for (final key in ['products', 'items', 'results']) {
          if (data[key] is List) return data[key] as List;
        }
      }
    }
    return const [];
  }
}