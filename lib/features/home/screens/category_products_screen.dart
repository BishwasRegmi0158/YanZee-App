import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/features/home/providers/category_products_provider.dart';
import 'package:yanzee_app/features/home/screens/widgets/product_card.dart';

class CategoryProductsScreen extends ConsumerWidget {
  final String categorySlug;
  final String displayName;

  const CategoryProductsScreen({
    super.key,
    required this.categorySlug,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(categoryProductsProvider(categorySlug));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          displayName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Something went wrong: $err')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products found in this category.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 240,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) => ProductCard(product: products[index]),
            ),
          );
        },
      ),
    );
  }
}