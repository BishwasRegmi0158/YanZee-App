class Product {
  final int id;
  final String brand;
  final String name;
  final String imageUrl;
  final double price;
  final double discountPercentage;
  final double rating;
  final String category;

  const Product({
    required this.id,
    required this.brand,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.category,
  });

  double get originalPrice {
    if (discountPercentage == 0) return price;
    return price / (1-(discountPercentage / 100));
  }


  factory Product.fromJson(Map<String, dynamic> json){

   return Product(
      id: json['id'] ?? 0,
      brand: json['brand'] ?? 'Unknown',
      name: json['title'] ?? '',
      imageUrl: json['thumbnail'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      category: json['category'] ?? '',
    );

  }
}
