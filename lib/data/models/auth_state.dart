import 'package:flutter/foundation.dart';

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
  });

  final int? id;
  final String? username;
  final String name;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? image;

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

  
  factory UserProfile.fromDummyJson(
    Map<String, dynamic> json, {
    String? overrideEmail,
  }) {
    final first = (json['firstName'] as String?) ?? '';
    final last = (json['lastName'] as String?) ?? '';
    final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');
    final email = overrideEmail ?? (json['email'] as String? ?? '');
    final emailName = nameFromEmail(email);
    return UserProfile(
      id: json['id'] is int ? json['id'] as int : null,
      username: json['username'] as String?,
      firstName: first,
      lastName: last,
      name: overrideEmail != null && emailName.isNotEmpty
          ? emailName
          : fullName.isNotEmpty
          ? fullName
          : (json['username'] as String? ?? ''),
      email: email,
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
  final List<ShippingAddress> _addresses = [];

  UserProfile? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null;
  List<ShippingAddress> get addresses => List.unmodifiable(_addresses);
  ShippingAddress? get defaultAddress {
    for (final address in _addresses) {
      if (address.isDefault) return address;
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

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
