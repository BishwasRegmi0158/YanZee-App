import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/core/storage/token_storage.dart';
import 'package:yanzee_app/data/models/auth_state.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  static const _json = {'Content-Type': 'application/json'};
  static const _timeout = Duration(seconds: 45); // Render free tier wakes slowly

  static String _msg(http.Response res, String fallback) {
    try {
      return (jsonDecode(res.body)['message'] as String?) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // ---------- POST /auth/register (returns no tokens) ----------
  static Future<void> register(Map<String, dynamic> body) async {
    late final http.Response res;
    try {
      res = await http
          .post(ApiConfig.register(), headers: _json, body: jsonEncode(body))
          .timeout(_timeout);
    } catch (_) {
      throw AuthException('Could not reach the server. Check your connection.');
    }
    if (res.statusCode != 201) {
      throw AuthException(_msg(res, 'Signup failed. Please try again.'));
    }
  }

  // ---------- POST /auth/login ----------
  static Future<UserProfile> login(String email, String password) async {
    late final http.Response res;
    try {
      res = await http
          .post(
            ApiConfig.login(),
            headers: _json,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);
    } catch (_) {
      throw AuthException('Could not reach the server. Check your connection.');
    }
    if (res.statusCode != 200) {
      throw AuthException(_msg(res, 'Login failed. Please try again.'));
    }

    final data = jsonDecode(res.body)['data'] as Map<String, dynamic>;
    final profile = UserProfile.fromApi(data['user'] as Map<String, dynamic>);
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;

    if (refresh != null) await TokenStorage.saveRefreshToken(refresh);
    AuthState.instance.login(profile, token: access, refreshToken: refresh);
    return profile;
  }

  // ---------- GET /auth/me ----------
  static Future<UserProfile> fetchMe({bool retry = true}) async {
    final token = AuthState.instance.token;
    if (token == null) throw AuthException('Not logged in.');

    late final http.Response res;
    try {
      res = await http
          .get(ApiConfig.me(), headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);
    } catch (_) {
      throw AuthException('Could not reach the server. Check your connection.');
    }

    if (res.statusCode == 401 && retry && await refreshToken()) {
      return fetchMe(retry: false);
    }
    if (res.statusCode != 200) throw AuthException('Could not load profile.');

    final data = jsonDecode(res.body)['data'];
    final userJson = (data is Map && data['user'] is Map) ? data['user'] : data;
    var profile = UserProfile.fromApi(userJson as Map<String, dynamic>);

    // Keep the known role if /me doesn't return one.
    final currentRole = AuthState.instance.user?.role;
    if (profile.role == null && currentRole != null) {
      profile = profile.copyWith(role: currentRole);
    }

    AuthState.instance.updateProfile(profile);
    return profile;
  }

  // ---------- POST /auth/refresh ----------
  static Future<bool> refreshToken() async {
    final rt = AuthState.instance.refreshToken;
    if (rt == null) return false;
    try {
      final res = await http
          .post(
            ApiConfig.refresh(),
            headers: _json,
            body: jsonEncode({'refreshToken': rt}),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        // refresh token is expired/revoked -> session is over
        await TokenStorage.clear();
        AuthState.instance.logout();
        return false;
      }

      final data = jsonDecode(res.body)['data'] as Map<String, dynamic>;
      final newAccess = data['accessToken'] as String;
      final newRefresh = (data['refreshToken'] as String?) ?? rt;
      await TokenStorage.saveRefreshToken(newRefresh);
      AuthState.instance.setTokens(newAccess, newRefresh);
      return true;
    } catch (_) {
      return false; // network problem: keep tokens, try again later
    }
  }

  // ---------- Restore session on app start (call from splash) ----------
  static Future<bool> restoreSession() async {
    final rt = await TokenStorage.readRefreshToken();
    if (rt == null) return false;

    AuthState.instance.setTokens(null, rt);
    if (!await refreshToken()) return false;

    try {
      await fetchMe();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------- POST /auth/logout ----------
  static Future<void> logout() async {
    try {
      await http
          .post(
            ApiConfig.logout(),
            headers: {
              ..._json,
              'Authorization': 'Bearer ${AuthState.instance.token}',
            },
            body: jsonEncode({'refreshToken': AuthState.instance.refreshToken}),
          )
          .timeout(_timeout);
    } catch (_) {
      // ignore: we still log out locally
    }
    await TokenStorage.clear();
    AuthState.instance.logout();
  }

  // TEMPORARY: local-only until you have the real update-profile endpoint.
  static Future<UserProfile> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? image,
  }) async {
    final current = AuthState.instance.user;
    final updated = (current ?? const UserProfile(name: '', email: '')).copyWith(
      name: name,
      email: email,
      phone: phone,
      image: image,
    );
    AuthState.instance.updateProfile(updated);
    return updated;
  }
}