
import 'package:flutter/foundation.dart';

class UserProfile {
  const UserProfile({required this.name, required this.email});

  final String name;
  final String email;
}

class AuthState extends ChangeNotifier {
  AuthState._();
  static final AuthState instance = AuthState._();

  UserProfile? _user;

  UserProfile? get user => _user;
  bool get isLoggedIn => _user != null;

  void login(UserProfile user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}