import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_repository_provider.dart';

class SellerOrdersNotifier extends AsyncNotifier<List<SellerOrder>> {
  @override
  Future<List<SellerOrder>> build() async {
    // NEW: reload the orders whenever the selected shop changes.
    await ref.watch(myShopProvider.future);
    return ref.watch(sellerRepositoryProvider).getOrders();
  }

  void updateStatus(String orderId, String newStatus) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData([
      for (final o in current)
        o.id == orderId ? o.copyWith(status: newStatus) : o,
    ]);
  }
}

// NEW: autoDispose, same reason as products.
final sellerOrdersProvider =
    AsyncNotifierProvider.autoDispose<SellerOrdersNotifier, List<SellerOrder>>(
      SellerOrdersNotifier.new,
    );