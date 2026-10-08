import 'package:flutter/foundation.dart';

/// Must match the backend enum exactly.
class UserRole {
  static const owner = 'OWNER';
  static const manager = 'MANAGER';
  static const orderManager = 'ORDER_MANAGER';
  static const viewer = 'VIEWER';
  static const superAdmin = 'SUPER_ADMIN';

  /// Roles that belong in the seller dashboard.
  static const staff = {owner, manager, orderManager, viewer};
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.id,
    this.phone,
    this.image,
    this.role,
    this.isActive,
  });

  final String? id;

  /// Backend field: fullName
  final String name;
  final String email;
  final String? phone;

  /// Backend field: profileImg
  final String? image;

  /// OWNER, MANAGER, ORDER_MANAGER, VIEWER or SUPER_ADMIN
  final String? role;
  final bool? isActive;

  static String nameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    final words = localPart
        .split(RegExp(r'[._-]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .toList();
    return words.join(' ');
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? image,
    String? role,
    bool? isActive,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }

  /// login: { id, fullName, email, phone, role }
  /// /auth/me: { id, fullName, email, phone, profileImg, isActive, role }
  factory UserProfile.fromApi(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString(),
      name: (json['fullName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      image: json['profileImg'] as String?,
      role: json['role'] as String?,
      isActive: json['isActive'] as bool?,
    );
  }
}

class AuthState extends ChangeNotifier {
  AuthState._();
  static final AuthState instance = AuthState._();

  UserProfile? _user;
  String? _token; // access token, memory only
  String? _refreshToken;

  UserProfile? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get isLoggedIn => _user != null;

  /// True for any seller-side staff role (OWNER, MANAGER, ORDER_MANAGER, VIEWER).
  bool get isShopOwner => UserRole.staff.contains(_user?.role);
  bool get isCustomer => isLoggedIn && !isShopOwner;

  /// Where this user should land after login/signup/app start.
  String get homeRoute => isShopOwner ? '/seller-dashboard' : '/home';

  void login(UserProfile user, {String? token, String? refreshToken}) {
    _user = user;
    _token = token ?? _token;
    _refreshToken = refreshToken ?? _refreshToken;
    notifyListeners();
  }

  void setTokens(String? access, String? refresh) {
    _token = access;
    _refreshToken = refresh;
    notifyListeners();
  }

  void updateProfile(UserProfile user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _token = null;
    _refreshToken = null;
    notifyListeners();
  }
}