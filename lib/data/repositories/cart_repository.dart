abstract class CartRepository {
  Future<Set<int>> getCartItems();
  Future<void> add(int productId);
  Future<void> remove(int productId);
}