import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_reviews_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_store_provider.dart';

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(sellerStoreProvider);
    final reviews = ref.watch(sellerReviewsProvider);
    final avg = averageRating(reviews);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F2),
        elevation: 0,
        title: const Text('Seller profile',
            style: TextStyle(fontFamily: AppFonts.brand, fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              backgroundImage: store.logoImage != null ? FileImage(store.logoImage!) : null,
              child: store.logoImage == null ? const Icon(Icons.storefront, size: 36) : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(store.name,
                style: const TextStyle(fontFamily: AppFonts.brand, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text('${avg.toStringAsFixed(1)} · ${reviews.length} reviews',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textGray)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.description, style: const TextStyle(fontSize: 13.5)),
                const Divider(height: 24),
                _infoRow(Icons.location_on_outlined, store.pickupAddress),
                const SizedBox(height: 8),
                _infoRow(Icons.percent_outlined, store.returnPolicy),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Reviews',
              style: TextStyle(fontFamily: AppFonts.brand, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No reviews yet', style: TextStyle(color: AppColors.textGray))),
            )
          else
            ...reviews.map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.gold, size: 14),
                            const SizedBox(width: 3),
                            Text(r.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateFmt.format(r.date), style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
                    const SizedBox(height: 8),
                    Text(r.comment, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textGray),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5))),
        ],
      );
}