import 'dart:io';

class SellerStore {
  final String name;
  final String description;
  final String contactEmail;
  final String address;
  final String contactPhone;
  final String returnPolicy;
  final File? logoImage; // freshly picked file (instant preview)
  final String? logoUrl; // saved logo URL from the backend

  const SellerStore({
    this.name = '',
    this.description = '',
    this.contactEmail = 'Not set',
    this.address = 'Not set',
    this.contactPhone = 'Not set',
    this.returnPolicy = 'Not set',
    this.logoImage,
    this.logoUrl,
  });

  SellerStore copyWith({
    String? name,
    String? description,
    String? contactEmail,
    String? address,
    String? contactPhone,
    String? returnPolicy,
    File? logoImage,
    String? logoUrl,
    bool clearLogo = false, // clears both the file and the URL
  }) {
    return SellerStore(
      name: name ?? this.name,
      description: description ?? this.description,
      contactEmail: contactEmail ?? this.contactEmail,
      address: address ?? this.address,
      contactPhone: contactPhone ?? this.contactPhone,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      logoImage: clearLogo ? null : (logoImage ?? this.logoImage),
      logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
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
