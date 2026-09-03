import 'package:yanzee_app/data/repositories/cart_repository.dart';

class InMemoryCartRepository implements CartRepository {
  final Set<int> _ids = {};

  @override
  Future<Set<int>> getCartItems() async => _ids;

  @override
  Future<void> add(int productId) async => _ids.add(productId);

  @override
  Future<void> remove(int productId) async => _ids.remove(productId);
}