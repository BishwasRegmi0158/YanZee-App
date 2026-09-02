import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/core/widgets/async_value_widget.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'section_header.dart';
import 'product_grid.dart';

class ProductSection extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final AsyncValue<List<Product>> value;
  final FutureProvider<List<Product>> provider;
  final VoidCallback? onSeeAll;

  const ProductSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.provider,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle, onSeeAll: onSeeAll),
          const SizedBox(height: 14),
          AsyncValueWidget(
            value: value,
            onRetry: () => ref.invalidate(provider),
            data: (products) => ProductGrid(products: products),
          ),
        ],
      ),
    );
  }
}
