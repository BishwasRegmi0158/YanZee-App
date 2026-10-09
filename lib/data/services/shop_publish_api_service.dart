import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';

final shopPublishApiServiceProvider =
    Provider((ref) => ShopPublishApiService());

class ShopPublishApiService {
  /// .../stores/toggle-publish with the x-store-id header.
  /// Tries POST, PATCH, then PUT. A 404 or 405 means "wrong method".
  Future<({bool isPublished, String message})> togglePublish(
    String storeId,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/stores/toggle-publish');

    Future<http.Response> send(String method) => ApiClient.send((h) async {
          final req = http.Request(method, url)
            ..headers.addAll({...h, 'x-store-id': storeId});
          return http.Response.fromStream(await req.send());
        });

    var res = await send('POST');
    for (final method in const ['PATCH', 'PUT']) {
      if (res.statusCode != 404 && res.statusCode != 405) break;
      res = await send(method);
    }

    if (res.statusCode != 200) {
      throw Exception(
        _message(res, 'Could not change publish status (${res.statusCode})'),
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final store = (body['data'] as Map<String, dynamic>)['updatedStore'] as Map;
    return (
      isPublished: store['isPublished'] == true,
      message: body['message']?.toString() ?? 'Done',
    );
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