class ShopCategory {
  final String id;
  final String name;
  final String slug;
  final String? image;
  final String? description;
  final String? seoTitle;
  final String? seoImage;
  final bool isAvailable;
  final DateTime? createdAt;
  final int productCount;

  const ShopCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.description,
    this.seoTitle,
    this.seoImage,
    this.isAvailable = true,
    this.createdAt,
    this.productCount = 0,
  });

  factory ShopCategory.fromJson(Map<String, dynamic> j) {
    final count = j['_count'];
    return ShopCategory(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      slug: j['slug']?.toString() ?? '',
      image: j['image']?.toString(),
      description: j['description']?.toString(),
      seoTitle: j['seoTitle']?.toString(),
      seoImage: j['seoImage']?.toString(),
      isAvailable: j['isAvailable'] == true,
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      productCount: count is Map ? (count['products'] as num?)?.toInt() ?? 0 : 0,
    );
  }

  ShopCategory copyWith({bool? isAvailable}) => ShopCategory(
        id: id,
        name: name,
        slug: slug,
        image: image,
        description: description,
        seoTitle: seoTitle,
        seoImage: seoImage,
        isAvailable: isAvailable ?? this.isAvailable,
        createdAt: createdAt,
        productCount: productCount,
      );
}