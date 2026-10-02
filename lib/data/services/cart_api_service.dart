// lib/data/services/cart_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_config.dart';
// If your ApiClient file is somewhere else, change only this import line.
import 'package:yanzee_app/core/api/api_client.dart';

class CartApiException implements Exception {
  final String message;
  final int? statusCode;
  const CartApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Every call needs the login token, so everything goes through
/// ApiClient.send (adds the Bearer token and retries once after a refresh).
class CartApiService {
  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}/carts$path');

  Map<String, String> _json(Map<String, String> auth) => {
        ...auth,
        'Content-Type': 'application/json',
      };

  /// GET /carts  ->  data {shops, selectedCount, totalItems, grandTotal}
  Future<Map<String, dynamic>> fetchCart() async {
    final res = await ApiClient.send((auth) => http.get(_uri(''), headers: auth));
    return _data(res, 'Could not load your cart');
  }

  /// POST /carts/items  {variantId, quantity}
  Future<void> addItem({
    required String variantId,
    required int quantity,
  }) async {
    final res = await ApiClient.send(
      (auth) => http.post(
        _uri('/items'),
        headers: _json(auth),
        body: jsonEncode({'variantId': variantId, 'quantity': quantity}),
      ),
    );
    _data(res, 'Could not add the item to your cart');
  }

  /// PATCH /carts/items/:itemId  {quantity, isSelected}
  /// [itemId] is the `itemId` from GET /carts (not the variantId).
  Future<void> updateItem(
    String itemId, {
    required int quantity,
    required bool isSelected,
  }) async {
    final res = await ApiClient.send(
      (auth) => http.patch(
        _uri('/items/$itemId'),
        headers: _json(auth),
        body: jsonEncode({'quantity': quantity, 'isSelected': isSelected}),
      ),
    );
    _data(res, 'Could not update the cart item');
  }

  /// PATCH /carts/select-all  {isSelected}
  Future<void> selectAll(bool isSelected) async {
    final res = await ApiClient.send(
      (auth) => http.patch(
        _uri('/select-all'),
        headers: _json(auth),
        body: jsonEncode({'isSelected': isSelected}),
      ),
    );
    _data(res, 'Could not update the selection');
  }

  /// PATCH /carts/select-shop  {shopId, isSelected}
  Future<void> selectShop(String shopId, bool isSelected) async {
    final res = await ApiClient.send(
      (auth) => http.patch(
        _uri('/select-shop'),
        headers: _json(auth),
        body: jsonEncode({'shopId': shopId, 'isSelected': isSelected}),
      ),
    );
    _data(res, 'Could not update the selection');
  }

  /// Unwraps {success, statusCode, message, data}. Some calls (select-all,
  /// select-shop) return no `data`, which is fine.
  Map<String, dynamic> _data(http.Response res, String fallback) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = body?['data'];
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    }
    throw CartApiException(
      (body?['message'] ?? fallback).toString(),
      res.statusCode,
    );
  }
}