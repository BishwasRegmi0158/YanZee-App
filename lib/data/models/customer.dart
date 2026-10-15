class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.createdAt,
  });

  static String? _orNull(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: _orNull(json['phone']),
        email: _orNull(json['email']),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}