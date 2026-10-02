import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_client.dart';
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/auth_state.dart';

// Multipart field name for POST /images/user.
// ASSUMED to be 'image' like the shop upload. Confirm in Postman.
const _userImageField = 'image';

class UserApiService {
  /// POST /images/user. Returns the new profileImg URL.
  Future<String> uploadProfileImage(File file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/images/user');
    final res = await ApiClient.send((h) async {
      final req = http.MultipartRequest('POST', url)
        ..headers.addAll(h)
        ..headers.remove('Content-Type')
        ..files.add(await http.MultipartFile.fromPath(_userImageField, file.path));
      return http.Response.fromStream(await req.send());
    });

    if (res.statusCode != 200 && res.statusCode != 201) {
      String msg = 'Image upload failed (${res.statusCode})';
      try {
        final m = (jsonDecode(res.body) as Map)['message'];
        if (m is String && m.isNotEmpty) msg = m;
      } catch (_) {}
      throw Exception(msg);
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>)['profileImg'] as String;
  }
}

/// Uploads the photo and updates the logged-in user in the app.
Future<void> changeProfileImage(File file) async {
  final url = await UserApiService().uploadProfileImage(file);
  final user = AuthState.instance.user;
  if (user != null) AuthState.instance.updateProfile(user.copyWith(image: url));
}