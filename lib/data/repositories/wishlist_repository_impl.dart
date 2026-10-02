// lib/data/repositories/wishlist_repository_impl.dart
import 'package:yanzee_app/data/repositories/wishlist_repository.dart';

class InMemoryWishlistRepository implements WishlistRepository {
  final Set<String> _ids = {};

  @override
  Future<Set<String>> getWishlistItems() async => _ids;

  @override
  Future<void> add(String productId) async => _ids.add(productId);

  @override
  Future<void> remove(String productId) async => _ids.remove(productId);

  @override
  Future<void> clear() async => _ids.clear();
}