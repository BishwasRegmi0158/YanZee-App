import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/services/seller_api_service.dart';

class SellerRepository {
  final SellerApiService _api = SellerApiService();

  Future<List<SellerProduct>> getAllProducts() async {
    final raw = await _api.fetchMyProducts(limit: 100); // dummyjson caps around ~194 total
    return raw.map((e) => SellerProduct.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SellerOrder>> getAllOrders() async {
    final carts = await _api.fetchCarts(limit: 50); // dummyjson's real max
    const statuses = ['New', 'Processing', 'Ready', 'On its way', 'Delivered', 'Declined'];
    final now = DateTime.now();

    final orders = await Future.wait(carts.asMap().entries.map((entry) async {
      final i = entry.key;
      final cart = entry.value as Map<String, dynamic>;
      var customerName = 'Customer #${cart['userId']}';
      try {
        final user = await _api.fetchUser(cart['userId'] as int);
        final full = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
        if (full.isNotEmpty) customerName = full;
      } catch (_) {
        // fall back to "Customer #<id>" set above
      }

      // Pull the first product in the cart as the row's headline item.
      final products = (cart['products'] as List?) ?? const [];
      final firstProduct = products.isNotEmpty ? products.first as Map<String, dynamic> : null;
      final productName = firstProduct != null
          ? (firstProduct['title'] as String? ?? '')
          : '';
      final productImageUrl = firstProduct != null
          ? (firstProduct['thumbnail'] as String? ?? '')
          : '';

      return SellerOrder(
        id: '${cart['id']}', // no leading '#' — the widget adds it where needed
        customerName: customerName,
        date: DateTime(now.year, now.month, now.day).subtract(Duration(days: i * 9)),
        itemCount: (cart['totalQuantity'] ?? 1) as int,
        total: (cart['total'] ?? 0).toDouble(),
        status: statuses[i % statuses.length],
        productName: productName,
        productImageUrl: productImageUrl,
      );
    }));

    return orders;
  }

  Future<List<SellerProduct>> getProducts() => getAllProducts();

  Future<List<SellerOrder>> getOrders() => getAllOrders();
}