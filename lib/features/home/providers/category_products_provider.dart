// lib/features/home/providers/category_products_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';

/// [category] is the backend enum (FASHION, HOME_DECOR, ...).
final categoryProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, category) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductsByCategory(category);
});