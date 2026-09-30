import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/services/auth_service.dart';


class ApiClient {
  static const _timeout = Duration(seconds: 45);

  static Map<String, String> _auth() => {
        'Authorization': 'Bearer ${AuthState.instance.token}',
      };

  static Future<http.Response> send(
    Future<http.Response> Function(Map<String, String> authHeaders) request,
  ) async {
    var res = await request(_auth()).timeout(_timeout);

    if (res.statusCode == 401) {
      final refreshed = await AuthService.refreshToken();
      if (!refreshed) {
        throw AuthException('Session expired. Please log in again.');
      }
      res = await request(_auth()).timeout(_timeout);
    }
    return res;
  }
}