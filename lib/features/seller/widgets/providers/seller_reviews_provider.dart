import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/seller_store.dart';


final sellerReviewsProvider = Provider<List<SellerReview>>((ref) {
  final now = DateTime.now();
  return [
    SellerReview(
      id: 'r1',
      customerName: 'Aayush Shrestha',
      rating: 5,
      comment: 'Beautiful craftsmanship, exactly as pictured. Fast dispatch too.',
      date: now.subtract(const Duration(days: 3)),
    ),
    SellerReview(
      id: 'r2',
      customerName: 'Priya Karki',
      rating: 4,
      comment: 'Great quality, packaging could be a bit sturdier.',
      date: now.subtract(const Duration(days: 9)),
    ),
    SellerReview(
      id: 'r3',
      customerName: 'Rojan Thapa',
      rating: 5,
      comment: 'Second time ordering from this seller — always reliable.',
      date: now.subtract(const Duration(days: 17)),
    ),
    SellerReview(
      id: 'r4',
      customerName: 'Sneha Gurung',
      rating: 4.5,
      comment: 'Lovely product, matched the description perfectly.',
      date: now.subtract(const Duration(days: 25)),
    ),
  ];
});

double averageRating(List<SellerReview> reviews) {
  if (reviews.isEmpty) return 0;
  return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
}