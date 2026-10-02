
abstract class WishlistRepository {
  Future<Set<String>> getWishlistItems();
  Future<void> add(String productId);
  Future<void> remove(String productId);
  Future<void> clear();
}