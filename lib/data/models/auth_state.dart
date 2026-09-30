import 'package:flutter/foundation.dart';

class UserRole {
  static const customer = 'CUSTOMER';
  static const shopOwner = 'SHOP_OWNER';
}

class ShippingAddress {
  const ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.province,
    required this.city,
    required this.street,
    this.isDefault = false,
  });

  final String fullName;
  final String phone;
  final String province;
  final String city;
  final String street;
  final bool isDefault;

  String get summary => '$street, $city, $province';

  ShippingAddress copyWith({
    String? fullName,
    String? phone,
    String? province,
    String? city,
    String? street,
    bool? isDefault,
  }) {
    return ShippingAddress(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      province: province ?? this.province,
      city: city ?? this.city,
      street: street ?? this.street,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

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
    this.role,
  });

  /// Backend ids are UUID strings.
  final String? id;
  final String? username;
  final String name;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? image;

  /// 'CUSTOMER' or 'SHOP_OWNER'
  final String? role;

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
      role: role ?? this.role,
    );
  }

  /// Backend user object: { id, fullName, email, phone, profileImg, role }
  factory UserProfile.fromApi(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString(),
      name: (json['fullName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      image: json['profileImg'] as String?,
      role: json['role'] as String?,
    );
  }
}

class AuthState extends ChangeNotifier {
  AuthState._();
  static final AuthState instance = AuthState._();

  UserProfile? _user;
  String? _token; // access token, memory only
  String? _refreshToken;
  final List<ShippingAddress> _addresses = [];

  UserProfile? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get isLoggedIn => _user != null;
  bool get isShopOwner => _user?.role == UserRole.shopOwner;
  bool get isCustomer => isLoggedIn && !isShopOwner;

  /// Where this user should land after login/signup/app start.
  String get homeRoute => isShopOwner ? '/seller-dashboard' : '/home';

  List<ShippingAddress> get addresses => List.unmodifiable(_addresses);
  ShippingAddress? get defaultAddress {
    for (final address in _addresses) {
      if (address.isDefault) return address;
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

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
    _addresses.clear();
    notifyListeners();
  }

  void saveAddress(ShippingAddress address) {
    final shouldBeDefault = _addresses.isEmpty || address.isDefault;
    if (shouldBeDefault) {
      for (var i = 0; i < _addresses.length; i++) {
        if (_addresses[i].isDefault) {
          _addresses[i] = _addresses[i].copyWith(isDefault: false);
        }
      }
    }
    _addresses.add(address.copyWith(isDefault: shouldBeDefault));
    notifyListeners();
  }

  void updateAddress(int index, ShippingAddress address) {
    if (index < 0 || index >= _addresses.length) return;
    if (address.isDefault) {
      for (var i = 0; i < _addresses.length; i++) {
        if (i != index && _addresses[i].isDefault) {
          _addresses[i] = _addresses[i].copyWith(isDefault: false);
        }
      }
    }
    _addresses[index] = address;
    if (!_addresses.any((a) => a.isDefault) && _addresses.isNotEmpty) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    notifyListeners();
  }

  void setDefaultAddress(int index) {
    if (index < 0 || index >= _addresses.length) return;
    for (var i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: i == index);
    }
    notifyListeners();
  }
}