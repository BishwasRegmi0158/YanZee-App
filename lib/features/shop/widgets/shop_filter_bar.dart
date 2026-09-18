import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yanzee_app/core/constants/categories.dart';
import 'package:yanzee_app/features/shop/provider/shop_provider.dart';

class ShopFilterBar extends StatefulWidget {
  final ShopFilters filters;
  final ValueChanged<ShopFilters> onChanged;

  const ShopFilterBar({super.key, required this.filters, required this.onChanged});

  @override
  State<ShopFilterBar> createState() => _ShopFilterBarState();
}

class _ShopFilterBarState extends State<ShopFilterBar> {
  late final ValueNotifier<String?> _categoryNotifier;
  late final ValueNotifier<String?> _sortNotifier;

  @override
  void initState() {
    super.initState();
    _categoryNotifier = ValueNotifier(widget.filters.category);
    _sortNotifier = ValueNotifier('${widget.filters.sortBy}_${widget.filters.order}');
  }

  @override
  void didUpdateWidget(covariant ShopFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the dropdowns' displayed value in sync if filters changed
    // from elsewhere (e.g. the filter sheet's "Apply" button).
    if (oldWidget.filters.category != widget.filters.category) {
      _categoryNotifier.value = widget.filters.category;
    }
    final newSortKey = '${widget.filters.sortBy}_${widget.filters.order}';
    if (_sortNotifier.value != newSortKey) {
      _sortNotifier.value = newSortKey;
    }
  }

  @override
  void dispose() {
    _categoryNotifier.dispose();
    _sortNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _styledDropdown<String>(
              valueListenable: _categoryNotifier,
              items: [
                const DropdownItem(value: 'all', child: Text('All Categories')),
                ...categoryLabels.map(
                  (label) => DropdownItem(
                    value: categorySlugMap[label], // slug is the real value sent to the API
                    child: Text(label),             // label is what the user sees
                  ),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                _categoryNotifier.value = v;
                widget.onChanged(widget.filters.copyWith(category: v));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _styledDropdown<String>(
              valueListenable: _sortNotifier,
              items: const [
                DropdownItem(value: 'title_asc', child: Text('Name A-Z')),
                DropdownItem(value: 'price_asc', child: Text('Price: Low-High')),
                DropdownItem(value: 'price_desc', child: Text('Price: High-Low')),
                DropdownItem(value: 'rating_desc', child: Text('Top Rated')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _sortNotifier.value = v;
                final parts = v.split('_');
                widget.onChanged(widget.filters.copyWith(sortBy: parts[0], order: parts[1]));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _styledDropdown<T>({
    required ValueListenable<T?> valueListenable,
    required List<DropdownItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: true,
        valueListenable: valueListenable,
        items: items,
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE3E0DC)),
            color: Colors.white,
          ),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }
}