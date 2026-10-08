import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';

// Multipart field name for POST /images/categories.
// Check the Body tab of that Postman request and change it if it differs.
const _imageField = 'image';

final categoryApiServiceProvider = Provider((ref) => CategoryApiService());

class CategoryApiService {
  Map<String, String> _withStore(Map<String, String> h, String storeId) => {
        ...h,
        'x-store-id': storeId,
      };

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

  /// POST /categories with the x-store-id header.
  Future<void> createCategory(
    String storeId, {
    required String name,
    required bool isAvailable,
    String? image,
    String? description,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/categories');
    final res = await ApiClient.send(
      (h) => http.post(
        url,
        headers: {..._withStore(h, storeId), 'Content-Type': 'application/json'},
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

  String _message(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      final msg = body is Map ? body['message'] : null;
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return fallback;
  }
}