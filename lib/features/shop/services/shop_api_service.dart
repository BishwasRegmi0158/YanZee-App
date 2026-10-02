import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';

class ShopApiService {
  /// Uploads a shop image and returns its public URL.
  Future<String> uploadShopImage(File file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/images/shop');
    final res = await ApiClient.send((h) async {
      // Built fresh on every call: a MultipartRequest can't be re-sent,
      // and ApiClient may retry once after refreshing the token.
      final req = http.MultipartRequest('POST', url)
        ..headers.addAll(h)
        ..headers.remove('Content-Type') // let multipart set its boundary
        ..files.add(await http.MultipartFile.fromPath('image', file.path));
      return http.Response.fromStream(await req.send());
    });

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_message(res, 'Image upload failed (${res.statusCode})'));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>)['url'] as String;
  }

  /// DELETE /shops/my
  Future<void> deleteMyShop() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops/my');
    final res = await ApiClient.send((h) => http.delete(url, headers: h));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        _message(res, 'Could not delete shop (${res.statusCode})'),
      );
    }
  }

  /// Returns null when the owner has no shop yet (404).
  Future<SellerShop?> getMyShop() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops/my');
    final res = await ApiClient.send((h) => http.get(url, headers: h));

    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception(_message(res, 'Failed to load shop (${res.statusCode})'));
    }
    return _parseShop(res);
  }

  Future<SellerShop> createShop({
    required String name,
    required String contactEmail,
    required String description,
    required String returnPolicy,
    required String address,
    required String contactPhone,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops');
    final res = await ApiClient.send(
      (h) => http.post(
        url,
        headers: {...h, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'contactEmail': contactEmail,
          'description': description,
          'returnPolicy': returnPolicy,
          'address': address,
          'contactPhone': contactPhone,
        }),
      ),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not create shop (${res.statusCode})'),
      );
    }
    return _parseShop(res);
  }

  SellerShop _parseShop(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return SellerShop.fromJson(data['shop'] as Map<String, dynamic>);
  }

  String _message(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      final msg = body is Map ? body['message'] : null;
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return fallback;
  }

  /// Signup details of the logged-in user (phone, address, city, ...).
  Future<Map<String, dynamic>> getMe() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/me');
    final res = await ApiClient.send((h) => http.get(url, headers: h));
    if (res.statusCode != 200) {
      throw Exception(
        _message(res, 'Failed to load profile (${res.statusCode})'),
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  Future<SellerShop> updateMyShop({
    required String name,
    required String contactEmail,
    required String description,
    required String returnPolicy,
    String? address,
    String? contactPhone,
    String? image, // null clears the shop image
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops/my');
    final res = await ApiClient.send(
      (h) => http.patch(
        url,
        headers: {...h, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'contactEmail': contactEmail,
          'description': description,
          'returnPolicy': returnPolicy,
          'image': image,
          if (address != null) 'address': address,
          if (contactPhone != null) 'contactPhone': contactPhone,
        }),
      ),
    );
    if (res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not update shop (${res.statusCode})'),
      );
    }
    return _parseShop(res);
  }
}

/// One-line address from the /auth/me signup data.
String signupAddress(Map<String, dynamic> me) {
  return [me['address'], me['city'], me['district'], me['province']]
      .map((e) => e?.toString().trim() ?? '')
      .where((s) => s.isNotEmpty)
      .join(', ');
}
