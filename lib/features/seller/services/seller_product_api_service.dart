import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';

// Multipart field name for POST /images/product/cover.
// ASSUMED to be 'image' like the shop upload. Confirm with the backend.
const _coverField = 'image';

class SellerProductApiService {
  Map<String, String> _json(Map<String, String> h) =>
      {...h, 'Content-Type': 'application/json'};

  /// POST /products
  /// body: {name, category, audience, status, price, discountPrice, image,
  ///        gallery, description, variants: [{size, stock, sku}]}
  Future<void> createProduct(Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products');
    final res = await ApiClient.send(
      (h) => http.post(url, headers: _json(h), body: jsonEncode(body)),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_message(res, 'Could not create product (${res.statusCode})'));
    }
  }

  /// PATCH /products/:id (same body shape as create)
  Future<void> updateProduct(String id, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/$id');
    final res = await ApiClient.send(
      (h) => http.patch(url, headers: _json(h), body: jsonEncode(body)),
    );
    if (res.statusCode != 200) {
      throw Exception(_message(res, 'Could not update product (${res.statusCode})'));
    }
  }

  /// DELETE /products/:id
  Future<void> deleteProduct(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products/$id');
    final res = await ApiClient.send((h) => http.delete(url, headers: h));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_message(res, 'Could not delete product (${res.statusCode})'));
    }
  }

  /// POST /images/product/cover, returns the image URL.
  Future<String> uploadCoverImage(File file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/images/product/cover');
    final res = await ApiClient.send((h) async {
      // Built fresh on every call: ApiClient may retry after a token refresh.
      final req = http.MultipartRequest('POST', url)
        ..headers.addAll(h)
        ..headers.remove('Content-Type')
        ..files.add(await http.MultipartFile.fromPath(_coverField, file.path));
      return http.Response.fromStream(await req.send());
    });
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_message(res, 'Image upload failed (${res.statusCode})'));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>)['url'] as String;
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