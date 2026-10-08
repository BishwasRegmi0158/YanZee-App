import 'dart:io';

class SellerStore {
  final String name;
  final String category; // backend value, e.g. PET_SUPPLIES ('' = not set)

  /// null until the owner sets one: the backend never returns it.
  final String? contactEmail;

  final String status; // e.g. ACTIVE
  final bool isPublished;
  final File? logoImage; // freshly picked file (instant preview)
  final String? logoUrl; // saved logo URL from the backend

  const SellerStore({
    this.name = '',
    this.category = '',
    this.contactEmail,
    this.status = '',
    this.isPublished = false,
    this.logoImage,
    this.logoUrl,
  });

  SellerStore copyWith({
    String? name,
    String? category,
    String? contactEmail,
    File? logoImage,
    String? logoUrl,
    bool clearLogo = false, // clears both the file and the URL
  }) {
    return SellerStore(
      name: name ?? this.name,
      category: category ?? this.category,
      contactEmail: contactEmail ?? this.contactEmail,
      status: status,
      isPublished: isPublished,
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