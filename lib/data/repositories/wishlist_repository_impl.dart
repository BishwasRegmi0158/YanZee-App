import 'package:yanzee_app/data/repositories/wishlist_repository.dart';

class InMemoryWishlistRepository implements WishlistRepository {
  final Set<int> _ids = {};

  @override
  Future<Set<int>> getWishlistItems() async => _ids;

  @override
  Future<void> add(int productId) async => _ids.add(productId);

  @override
  Future<void> remove(int productId) async => _ids.remove(productId);
}