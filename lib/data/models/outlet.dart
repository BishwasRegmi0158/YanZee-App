class Outlet {
  final String id;
  final String name;
  final String? address;
  final String? contactPerson;
  final String? contactPhone;
  final bool isMain;
  final bool isActive;
  final DateTime? createdAt;

  const Outlet({
    required this.id,
    required this.name,
    this.address,
    this.contactPerson,
    this.contactPhone,
    this.isMain = false,
    this.isActive = true,
    this.createdAt,
  });

  Outlet copyWith({bool? isActive}) => Outlet(
        id: id,
        name: name,
        address: address,
        contactPerson: contactPerson,
        contactPhone: contactPhone,
        isMain: isMain,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  static String? _orNull(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory Outlet.fromJson(Map<String, dynamic> json) => Outlet(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        address: _orNull(json['address']),
        contactPerson: _orNull(json['contactPerson']),
        contactPhone: _orNull(json['contactPhone']),
        isMain: json['isMain'] == true,
        isActive: json['isActive'] != false,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}