import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final repository = ref.watch(productRepositoryProvider);
  return repository.searchProducts(query);
});