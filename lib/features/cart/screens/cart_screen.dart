import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
import 'package:yanzee_app/features/home/providers/product_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // Selection is screen-local UI state, not persisted with the cart itself.
  final Set<int> _selectedIds = {};
  bool _initializedSelection = false;

  @override
  Widget build(BuildContext context) {
    final cartMap = ref.watch(cartProvider); // Map<productId, quantity>

    // Default: everything selected the first time items exist.
    if (!_initializedSelection && cartMap.isNotEmpty) {
      _selectedIds.addAll(cartMap.keys);
      _initializedSelection = true;
    }
    // Drop selections for items no longer in the cart (e.g. removed elsewhere).
    _selectedIds.removeWhere((id) => !cartMap.containsKey(id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cart',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          if (cartMap.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
              tooltip: 'Delete selected',
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: cartMap.isEmpty ? _EmptyCart() : _buildBody(context, cartMap),
    );
  }

  Widget _buildBody(BuildContext context, Map<int, int> cartMap) {
    final allSelected =
        _selectedIds.length == cartMap.length && cartMap.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: allSelected,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedIds
                        ..clear()
                        ..addAll(cartMap.keys);
                    } else {
                      _selectedIds.clear();
                    }
                  });
                },
              ),
              Text(
                'Select all · ${_selectedIds.length} selected',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cartMap.length,
            itemBuilder: (context, index) {
              final productId = cartMap.keys.elementAt(index);
              final quantity = cartMap[productId]!;
              return _CartLineItem(
                productId: productId,
                quantity: quantity,
                isSelected: _selectedIds.contains(productId),
                onSelectedChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedIds.add(productId);
                    } else {
                      _selectedIds.remove(productId);
                    }
                  });
                },
              );
            },
          ),
        ),
        _CartCheckoutBar(selectedIds: _selectedIds),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove items?'),
        content: Text(
          'Remove ${_selectedIds.length} selected item${_selectedIds.length == 1 ? '' : 's'} from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).removeIds(_selectedIds);
              setState(() => _selectedIds.clear());
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row: checkbox + product info (fetched by id) + quantity stepper.
class _CartLineItem extends ConsumerWidget {
  final int productId;
  final int quantity;
  final bool isSelected;
  final ValueChanged<bool?> onSelectedChanged;

  const _CartLineItem({
    required this.productId,
    required this.quantity,
    required this.isSelected,
    required this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));

    return productAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (product) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Checkbox(value: isSelected, onChanged: onSelectedChanged),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () =>
                    context.push('/product/${product.id}', extra: product),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${product.price.toStringAsFixed(2)} each',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Stepper + total price sit outside the InkWell so they
            // don't trigger navigation when tapped.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(product.price * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                _QuantityStepper(productId: productId, quantity: quantity),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  final int productId;
  final int quantity;

  const _QuantityStepper({required this.productId, required this.quantity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _StepperButton(
          icon: Icons.remove,
          onTap: () => ref.read(cartProvider.notifier).decrement(productId),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        _StepperButton(
          icon: Icons.add,
          onTap: () => ref.read(cartProvider.notifier).increment(productId),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

/// Bottom bar — subtotal computed ONLY from selected items.
class _CartCheckoutBar extends ConsumerWidget {
  final Set<int> selectedIds;

  const _CartCheckoutBar({required this.selectedIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartMap = ref.watch(cartProvider);

    double subtotal = 0;
    int itemCount = 0;

    for (final id in selectedIds) {
      final quantity = cartMap[id];
      if (quantity == null) continue;
      final productAsync = ref.watch(productByIdProvider(id));
      final product = productAsync.value;
      if (product == null) continue; // still loading or errored — skip from total
      subtotal += product.price * quantity;
      itemCount += quantity;
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$itemCount item${itemCount == 1 ? '' : 's'} selected',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '\$${subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedIds.isEmpty ? Colors.grey.shade300 : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: selectedIds.isEmpty
                  ? null
                  : () {
                      // TODO: wire to checkout flow when it's built
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checkout coming soon')),
                      );
                    },
              child: const Text(
                'Checkout',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Your cart is empty',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Add products to your cart to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.go('/home'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text('Browse products', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}