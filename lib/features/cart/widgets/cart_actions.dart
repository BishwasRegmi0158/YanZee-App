// lib/features/cart/widgets/cart_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
import 'package:yanzee_app/features/cart/widgets/variant_picker_sheet.dart';

void showCartSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
      ),
    );
}

/// Adds [product] to the backend cart.
/// - one size in stock  -> added directly (quantity 1)
/// - several sizes      -> opens the size + quantity sheet first
/// Returns true when the item really was added.
Future<bool> addProductToCart(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  if (product.variants.isEmpty) {
    showCartSnack(context, 'This product has no sizes available yet');
    return false;
  }
  final available = product.availableVariants;
  if (available.isEmpty) {
    showCartSnack(context, 'This product is out of stock');
    return false;
  }

  VariantSelection? selection;
  if (available.length == 1) {
    selection = VariantSelection(variant: available.first, quantity: 1);
  } else {
    selection = await showVariantPickerSheet(
      context,
      product: product,
      confirmLabel: 'Add to Cart',
    );
  }
  if (selection == null || !context.mounted) return false;

  final error = await ref.read(cartProvider.notifier).addItem(
        variantId: selection.variant.id,
        quantity: selection.quantity,
      );
  if (!context.mounted) return false;

  showCartSnack(context, error ?? 'Added to cart');
  return error == null;
}