/// The 11 store categories the backend accepts.
const kStoreCategories = [
  'GENERAL',
  'FASHION',
  'BEAUTY',
  'ELECTRONICS',
  'GROCERY',
  'PHARMACY',
  'PET_SUPPLIES',
  'SPORTS',
  'RESTAURANTS',
  'HOME_DECOR',
  'OTHER',
];

/// PET_SUPPLIES -> "Pet Supplies". Empty -> "Not set".
String storeCategoryLabel(String api) {
  if (api.isEmpty) return 'Not set';
  return api
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
      .join(' ');
}

class SellerShop {
  final String id;
  final String name;
  final String slug;
  final String? logo;
  final String status;
  final bool isPublished;
  final String category;

  /// The store APIs don't return these yet, so they are usually null.
  final String? contactEmail;
  final String? contactPhone;
  final String? storeAddress;

  const SellerShop({
    required this.id,
    required this.name,
    this.slug = '',
    this.logo,
    this.status = '',
    this.isPublished = false,
    this.category = '',
    this.contactEmail,
    this.contactPhone,
    this.storeAddress,
  });

  /// Older screens read `image`; it is the same as `logo`.
  String? get image => logo;

  static String? _orNull(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory SellerShop.fromJson(Map<String, dynamic> json) => SellerShop(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        logo: _orNull(json['logo']),
        status: json['status']?.toString() ?? '',
        isPublished: json['isPublished'] == true,
        category: json['category']?.toString() ?? '',
        contactEmail: _orNull(json['contactEmail']),
        contactPhone: _orNull(json['contactPhone']),
        storeAddress: _orNull(json['storeAddress']),
      );
}