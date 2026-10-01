class SellerShop {
  final String id;
  final String name;
  final String description;
  final String contactEmail;
  final String returnPolicy;
  final String? image;
  final String? address;
  final String? contactPhone;

  const SellerShop({
    required this.id,
    required this.name,
    required this.description,
    required this.contactEmail,
    required this.returnPolicy,
    this.image,
    this.address,
    this.contactPhone,
  });

  static String? _orNull(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory SellerShop.fromJson(Map<String, dynamic> json) => SellerShop(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        contactEmail: json['contactEmail']?.toString() ?? '',
        returnPolicy: json['returnPolicy']?.toString() ?? '',
        image: _orNull(json['image']),
        address: _orNull(json['address']),
        contactPhone: _orNull(json['contactPhone']),
      );
}