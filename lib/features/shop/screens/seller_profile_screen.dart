import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';
import 'package:yanzee_app/data/models/seller_store.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_reviews_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_store_provider.dart';

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  /// A freshly picked file wins (instant preview); otherwise the saved URL.
  ImageProvider? _getLogoProvider(File? logoFile, String? logoUrl) {
    if (logoFile != null) {
      return ResizeImage(FileImage(logoFile), width: 300, height: 300);
    }
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ResizeImage(NetworkImage(logoUrl), width: 300, height: 300);
    }
    return null;
  }

  /// "ACTIVE" + published -> "Active · Published".
  String _statusText(SellerStore store) {
    final status = store.status.isEmpty
        ? 'Unknown'
        : '${store.status[0]}${store.status.substring(1).toLowerCase()}';
    return '$status · ${store.isPublished ? 'Published' : 'Not published'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final store = ref.watch(sellerStoreProvider);
    final reviews = ref.watch(sellerReviewsProvider);
    final avg = averageRating(reviews);
    final dateFmt = DateFormat('dd MMM yyyy');
    final logoProvider = _getLogoProvider(store.logoImage, store.logoUrl);
    final email = store.contactEmail;

    return Scaffold(
      appBar: AppBar(title: const Text('Seller profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: colors.surfaceContainerLowest,
              backgroundImage: logoProvider,
              child: logoProvider == null
                  ? Icon(
                      Iconsax.shop,
                      size: 36,
                      color: colors.onSurfaceVariant,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(store.name, style: context.text.headlineMedium),
          ),
          const SizedBox(height: 4),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.star1, color: context.status.warningFg, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${avg.toStringAsFixed(1)} · ${reviews.length} reviews',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  context,
                  Iconsax.category,
                  storeCategoryLabel(store.category),
                ),
                const SizedBox(height: 8),
                _infoRow(context, Iconsax.tick_circle, _statusText(store)),
                if (email != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(context, Iconsax.sms, email),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Reviews', style: context.text.headlineSmall),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No reviews yet',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            )
          else
            ...reviews.map(
              (r) => _SurfaceCard(
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: context.status.warningFg,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              r.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFmt.format(r.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
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

  Widget _infoRow(BuildContext context, IconData icon, String value) => Row(
        children: [
          Icon(icon, size: 16, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      );
}

/// White rounded card with the website's thin border.
class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.margin = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.r2xl),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}