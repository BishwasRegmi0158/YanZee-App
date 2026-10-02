// lib/features/cart/widgets/variant_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/product.dart';

class VariantSelection {
  final ProductVariant variant;
  final int quantity;
  const VariantSelection({required this.variant, required this.quantity});
}

/// Bottom sheet: choose a size and a quantity. Returns null if dismissed.
Future<VariantSelection?> showVariantPickerSheet(
  BuildContext context, {
  required Product product,
  required String confirmLabel,
  String? initialVariantId,
}) {
  return showModalBottomSheet<VariantSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _VariantPickerSheet(
      product: product,
      confirmLabel: confirmLabel,
      initialVariantId: initialVariantId,
    ),
  );
}

/// Size chips. Out-of-stock sizes are greyed out and cannot be selected.
class SizeChips extends StatelessWidget {
  const SizeChips({
    super.key,
    required this.variants,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ProductVariant> variants;
  final String? selectedId;
  final ValueChanged<ProductVariant> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: variants.map((v) {
        final selected = v.id == selectedId;
        return ChoiceChip(
          label: Text(v.size),
          selected: selected,
          showCheckmark: false,
          selectedColor: Colors.black,
          backgroundColor: Colors.white,
          disabledColor: Colors.grey.shade100,
          side: BorderSide(
            color: selected ? Colors.black : Colors.grey.shade300,
          ),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (v.inStock ? Colors.black87 : Colors.grey.shade400),
            decoration: v.inStock ? null : TextDecoration.lineThrough,
          ),
          onSelected: v.inStock ? (_) => onSelected(v) : null,
        );
      }).toList(),
    );
  }
}

class _VariantPickerSheet extends StatefulWidget {
  const _VariantPickerSheet({
    required this.product,
    required this.confirmLabel,
    required this.initialVariantId,
  });

  final Product product;
  final String confirmLabel;
  final String? initialVariantId;

  @override
  State<_VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<_VariantPickerSheet> {
  ProductVariant? _selected;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    for (final v in widget.product.variants) {
      if (v.id == widget.initialVariantId && v.inStock) _selected = v;
    }
    if (_selected == null) {
      final available = widget.product.availableVariants;
      if (available.length == 1) _selected = available.first;
    }
  }

  void _select(ProductVariant v) {
    setState(() {
      _selected = v;
      if (_quantity > v.stock) _quantity = v.stock;
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final selected = _selected;
    final maxQty = selected?.stock ?? 1;
    final total = product.price * _quantity;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select size',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: product.imageUrl.isEmpty
                        ? _thumbPlaceholder()
                        : Image.network(
                            product.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPrice(product.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (product.hasDiscount)
                        Text(
                          formatPrice(product.originalPrice),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizeChips(
              variants: product.variants,
              selectedId: selected?.id,
              onSelected: _select,
            ),
            if (selected != null && selected.stock <= 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Only ${selected.stock} left',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFE53935)),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantity', style: TextStyle(fontSize: 14)),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: _quantity < maxQty
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  formatPrice(total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: selected == null
                    ? null
                    : () => Navigator.of(context).pop(
                          VariantSelection(
                            variant: selected,
                            quantity: _quantity,
                          ),
                        ),
                child: Text(
                  selected == null ? 'Select a size' : widget.confirmLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        width: 48,
        height: 48,
        color: Colors.grey.shade100,
        child: const Icon(Icons.image_not_supported_outlined, size: 20),
      );
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.black87 : Colors.grey.shade400,
        ),
      ),
    );
  }
}