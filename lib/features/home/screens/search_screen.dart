import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/features/home/providers/search_provider.dart';
import 'package:yanzee_app/features/home/screens/widgets/product_card.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search products, brands...',
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              ref.read(searchQueryProvider.notifier).state = value,
        ),
      ),
      body: query.trim().isEmpty
          ? const Center(child: Text('Start typing to search'))
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('No products found'));
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
                    itemBuilder: (context, index) =>
                        ProductCard(product: products[index]),
                  ),
                );
              },
            ),
    );
  }
}