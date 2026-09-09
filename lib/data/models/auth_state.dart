import 'package:flutter/foundation.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.phone,
    this.image,
  });

  final int? id;
  final String? username;
  final String name;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? image;

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? image,
  }) {
    return UserProfile(
      id: id,
      username: username,
      firstName: firstName,
      lastName: lastName,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
    );
  }

  /// Builds a profile from a DummyJSON /auth/login or /auth/me response.
  /// [overrideEmail] keeps whatever email the person actually typed in
  /// the login form, since DummyJSON's seeded account has its own email.
  factory UserProfile.fromDummyJson(
    Map<String, dynamic> json, {
    String? overrideEmail,
  }) {
    final first = (json['firstName'] as String?) ?? '';
    final last = (json['lastName'] as String?) ?? '';
    final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');
    return UserProfile(
      id: json['id'] is int ? json['id'] as int : null,
      username: json['username'] as String?,
      firstName: first,
      lastName: last,
      name: fullName.isNotEmpty ? fullName : (json['username'] as String? ?? ''),
      email: overrideEmail ?? (json['email'] as String? ?? ''),
      phone: json['phone'] as String?,
      image: json['image'] as String?,
    );
  }
}

class AuthState extends ChangeNotifier {
  AuthState._();
  static final AuthState instance = AuthState._();

  UserProfile? _user;
  String? _token;

  UserProfile? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null;

  void login(UserProfile user, {String? token}) {
    _user = user;
    _token = token ?? _token;
    notifyListeners();
  }

  void updateProfile(UserProfile user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _token = null;
    notifyListeners();
  }
}