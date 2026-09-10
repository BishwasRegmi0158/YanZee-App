abstract class WishlistRepository {
  Future<Set<int>> getWishlistItems();
  Future<void> add(int productId);
  Future<void> remove(int productId);
  Future<void> clear();
}