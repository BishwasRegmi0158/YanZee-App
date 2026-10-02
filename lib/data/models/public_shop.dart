class PublicShop {
  final String id;
  final String name;
  final String? image;
  final String description;
  final String contactEmail;
  final String returnPolicy;
  final String? contactPhone;
  final String? address;
  final String ownerName;
  final String? ownerImage;
  final int productCount;

  const PublicShop({
    required this.id,
    required this.name,
    required this.description,
    required this.contactEmail,
    required this.returnPolicy,
    required this.ownerName,
    required this.productCount,
    this.image,
    this.contactPhone,
    this.address,
    this.ownerImage,
  });

  factory PublicShop.fromJson(Map<String, dynamic> json) {
    final owner = (json['owner'] as Map?) ?? const {};
    final count = (json['_count'] as Map?) ?? const {};
    return PublicShop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      description: json['description']?.toString() ?? '',
      contactEmail: json['contactEmail']?.toString() ?? '',
      returnPolicy: json['returnPolicy']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString(),
      address: json['address']?.toString(),
      ownerName: owner['fullName']?.toString() ?? '',
      ownerImage: owner['profileImg']?.toString(),
      productCount: (count['products'] as num?)?.toInt() ?? 0,
    );
  }
}