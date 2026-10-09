import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';

// Multipart field name for POST /images/store-logo.
// Check the Body tab of that Postman request and change it if it differs.
const _logoField = 'image';

class ShopApiService {
  Uri get _stores => Uri.parse('${ApiConfig.baseUrl}/stores');

  Map<String, String> _withStore(Map<String, String> h, String storeId) => {
        ...h,
        'x-store-id': storeId,
      };

  Map<String, String> _json(Map<String, String> h) => {
        ...h,
        'Content-Type': 'application/json',
      };

  /// ApiClient adds x-store-id to every request. Listing shops and creating
  /// a shop are not about one particular shop, so we take it off here.
  Map<String, String> _noStore(Map<String, String> h) =>
      {...h}..remove('x-store-id');

  /// GET /stores. Returns every store the owner has (empty list if none).
  Future<List<SellerShop>> getMyShops() async {
    final res = await ApiClient.send(
      (h) => http.get(_stores, headers: _noStore(h)),
    );

    if (res.statusCode == 404) return [];
    if (res.statusCode != 200) {
      throw Exception(_message(res, 'Failed to load stores (${res.statusCode})'));
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    final stores = data is Map ? data['stores'] : null;
    if (stores is! List) return [];
    return stores
        .map((s) => SellerShop.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList();
  }

  /// The first store, or null when the owner has none.
  Future<SellerShop?> getMyShop() async {
    final shops = await getMyShops();
    return shops.isEmpty ? null : shops.first;
  }

  /// POST /stores
  Future<SellerShop> createShop({
    required String name,
    required String category,
    required String contactEmail,
    required String contactPhone,
    required String storeAddress,
  }) async {
    final res = await ApiClient.send(
      (h) => http.post(
        _stores,
        headers: _json(_noStore(h)),
        body: jsonEncode({
          'name': name,
          'category': category,
          'contactEmail': contactEmail,
          'contactPhone': contactPhone,
          'storeAddress': storeAddress,
        }),
      ),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not create store (${res.statusCode})'),
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final store = (body['data'] as Map<String, dynamic>)['store']
        as Map<String, dynamic>;
    // The response only has id, name and slug, so keep what was just entered.
    return SellerShop(
      id: store['id']?.toString() ?? '',
      name: store['name']?.toString() ?? name,
      slug: store['slug']?.toString() ?? '',
      category: category,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      storeAddress: storeAddress,
    );
  }

  /// PATCH /stores with the x-store-id header.
  /// The backend only accepts name, category and contactEmail here.
  Future<void> updateMyShop(
    String storeId, {
    String? name,
    String? category,
    String? contactEmail,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (contactEmail != null) 'contactEmail': contactEmail,
    };

    final res = await ApiClient.send(
      (h) => http.patch(
        _stores,
        headers: _withStore(_json(h), storeId),
        body: jsonEncode(body),
      ),
    );

    if (res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not update store (${res.statusCode})'),
      );
    }
  }

  /// POST /images/store-logo with the x-store-id header.
  Future<String> uploadStoreLogo(String storeId, File file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/images/store-logo');
    final res = await ApiClient.send((h) async {
      final req = http.MultipartRequest('POST', url)
        ..headers.addAll(_withStore(h, storeId))
        ..headers.remove('Content-Type') // let multipart set its boundary
        ..files.add(await http.MultipartFile.fromPath(_logoField, file.path));
      return http.Response.fromStream(await req.send());
    });

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_message(res, 'Image upload failed (${res.statusCode})'));
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final store = (body['data'] as Map<String, dynamic>)['store']
        as Map<String, dynamic>;
    final logo = store['logo']?.toString();
    if (logo == null || logo.isEmpty) {
      throw Exception('Upload worked but no logo URL came back.');
    }
    return logo;
  }

  /// DELETE /stores with the x-store-id header.
  Future<void> deleteStore(String storeId) async {
    final res = await ApiClient.send(
      (h) => http.delete(_stores, headers: _withStore(h, storeId)),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        _message(res, 'Could not delete store (${res.statusCode})'),
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

  /// Logged-in user details (GET /auth/me).
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
}