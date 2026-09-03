import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';

final categoryProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, categorySlug) {
  final repository = ref.watch(productRepositoryProvider); // match your actual repo provider name
  return repository.getProductsByCategory(categorySlug);
});