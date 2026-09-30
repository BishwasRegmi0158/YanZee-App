import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Only the refresh token is persisted. The access token lives in memory.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _kRefresh = 'refresh_token';
  static const _kInitialized = 'auth_storage_initialized';

  /// Call once at app start, before restoreSession().
  /// iOS keeps Keychain data after uninstall, but normal app storage is wiped.
  /// If the flag is missing this is a fresh install, so clear any leftovers.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_kInitialized) ?? false)) {
        await _storage.deleteAll();
        await prefs.setBool(_kInitialized, true);
      }
    } catch (_) {
      // Never block app start because of storage problems.
    }
  }

  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _kRefresh, value: token);

  /// Returns null if nothing is saved or the stored data can't be read
  /// (this can happen on Android after a backup restore).
  static Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: _kRefresh);
    } catch (_) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  static Future<void> clear() => _storage.delete(key: _kRefresh);
}