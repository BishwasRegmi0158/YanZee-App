import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final newArrivalsProvider = FutureProvider<List<Product>>((ref) async {
  final productRepository = ref.watch(productRepositoryProvider);
  return productRepository.getNewArrivals();
});
final allNewArrivalsProvider = FutureProvider<List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getNewArrivals(limit: 50);
});