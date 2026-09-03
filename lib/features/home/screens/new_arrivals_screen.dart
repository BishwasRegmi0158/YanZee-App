import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';
import 'package:yanzee_app/features/home/screens/widgets/product_card.dart';

class NewArrivalsScreen extends ConsumerWidget {
  const NewArrivalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allNewArrivalsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('New Arrivals', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) => Padding(
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
        ),
      ),
    );
  }
}