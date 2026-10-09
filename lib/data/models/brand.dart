class Brand {
  final String id;
  final String name;
  final String slug;
  final String? logo;
  final String? description;
  final String? seoTitle;
  final String? seoImage;
  final bool isAvailable;
  final DateTime? createdAt;
  final int productCount;

  const Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    this.description,
    this.seoTitle,
    this.seoImage,
    this.isAvailable = true,
    this.createdAt,
    this.productCount = 0,
  });

  factory Brand.fromJson(Map<String, dynamic> j) {
    final count = j['_count'];
    return Brand(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      slug: j['slug']?.toString() ?? '',
      logo: j['logo']?.toString(),
      description: j['description']?.toString(),
      seoTitle: j['seoTitle']?.toString(),
      seoImage: j['seoImage']?.toString(),
      isAvailable: j['isAvailable'] != false,
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      productCount: count is Map ? (count['products'] as num?)?.toInt() ?? 0 : 0,
    );
  }

  Brand copyWith({String? name, bool? isAvailable}) => Brand(
        id: id,
        name: name ?? this.name,
        slug: slug,
        logo: logo,
        description: description,
        seoTitle: seoTitle,
        seoImage: seoImage,
        isAvailable: isAvailable ?? this.isAvailable,
        createdAt: createdAt,
        productCount: productCount,
      );
}