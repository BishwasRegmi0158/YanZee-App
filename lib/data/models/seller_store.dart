import 'dart:io';

class SellerStore {
  final String name;
  final String description;
  final String pickupAddress;
  final String contactNumber;
  final String returnPolicy;
  final File? logoImage; // session-only until backend upload exists

  const SellerStore({
    this.name = 'YanZee Atelier',
    this.description = 'Handmade Nepali crafts & textiles',
    this.pickupAddress = 'Not set',
    this.contactNumber = 'Not set',
    this.returnPolicy = '7-day returns',
    this.logoImage,
  });

  SellerStore copyWith({
    String? name,
    String? description,
    String? pickupAddress,
    String? contactNumber,
    String? returnPolicy,
    File? logoImage,
    bool clearLogo = false,
  }) {
    return SellerStore(
      name: name ?? this.name,
      description: description ?? this.description,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      contactNumber: contactNumber ?? this.contactNumber,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      logoImage: clearLogo ? null : (logoImage ?? this.logoImage),
    );
  }
}

class SellerReview {
  final String id;
  final String customerName;
  final double rating; // 1-5
  final String comment;
  final DateTime date;

  const SellerReview({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}