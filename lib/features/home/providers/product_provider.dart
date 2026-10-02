// lib/features/home/providers/product_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final newArrivalsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getNewArrivals();
});

final allNewArrivalsProvider = FutureProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getNewArrivals(limit: 50);
});

/// Product ids are UUID strings now.
final productByIdProvider =
    FutureProvider.family<Product, String>((ref, id) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProductById(id);
});

/// shopId -> shop name, shown on the product screen instead of the brand.
final shopNameProvider =
    FutureProvider.family<String, String>((ref, shopId) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getShopName(shopId);
});