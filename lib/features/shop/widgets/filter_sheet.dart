import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/core/constants/categories.dart';
import 'package:yanzee_app/features/shop/provider/shop_provider.dart';

Future<void> showFilterSheet(BuildContext context, WidgetRef ref) {
  final shopState = ref.read(shopProvider);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true, // keeps the sheet clear of the status bar/notch
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _FilterSheetContent(
      initial: shopState.filters,
      loadedProducts: shopState.products,
    ),
  );
}

class _FilterSheetContent extends ConsumerStatefulWidget {
  final ShopFilters initial;
  final List<dynamic>
  loadedProducts; // List<Product>, kept loose here to avoid an extra import cycle

  const _FilterSheetContent({
    required this.initial,
    required this.loadedProducts,
  });

  @override
  ConsumerState<_FilterSheetContent> createState() =>
      _FilterSheetContentState();
}

class _FilterSheetContentState extends ConsumerState<_FilterSheetContent> {
  late String _category;
  late String _sortKey; // combined 'sortBy_order'
  late double _maxPrice;
  late double _minRating;

  late double _catalogMinPrice;
  late double _catalogMaxPrice;

  static const List<_SortOption> _sortOptions = [
    _SortOption('Featured', 'title_asc'),
    _SortOption('Price: low to high', 'price_asc'),
    _SortOption('Price: high to low', 'price_desc'),
    _SortOption('Top rated', 'rating_desc'),
  ];

  @override
  void initState() {
    super.initState();

    final prices = widget.loadedProducts
        .map((p) => (p.price as num).toDouble())
        .toList();
    _catalogMinPrice = prices.isEmpty
        ? 0
        : prices.reduce((a, b) => a < b ? a : b);
    _catalogMaxPrice = prices.isEmpty
        ? 2000
        : prices.reduce((a, b) => a > b ? a : b);
    if (_catalogMaxPrice <= _catalogMinPrice) {
      _catalogMaxPrice = _catalogMinPrice + 100;
    }

    _category = widget.initial.category;
    _sortKey = '${widget.initial.sortBy}_${widget.initial.order}';
    _maxPrice = widget.initial.maxPrice ?? _catalogMaxPrice;
    if (_maxPrice < _catalogMinPrice || _maxPrice > _catalogMaxPrice) {
      _maxPrice = _catalogMaxPrice;
    }
    _minRating = widget.initial.minRating ?? 0;
  }

  void _reset() {
    setState(() {
      _category = 'all';
      _sortKey = 'title_asc';
      _maxPrice = _catalogMaxPrice;
      _minRating = 0;
    });
  }

  void _apply() {
    final parts = _sortKey.split('_');
    ref
        .read(shopProvider.notifier)
        .updateFilters(
          ShopFilters(
            category: _category,
            sortBy: parts[0],
            order: parts[1],
            minPrice: null,
            maxPrice: _maxPrice < _catalogMaxPrice ? _maxPrice : null,
            minRating: _minRating > 0 ? _minRating : null,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: _category == 'all',
                    onTap: () => setState(() => _category = 'all'),
                  ),
                  ...categoryLabels.map((label) {
                    final slug = categorySlugMap[label]!;
                    return _CategoryChip(
                      label: label,
                      selected: _category == slug,
                      onTap: () => setState(() => _category = slug),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Max price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Max price',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  Text(
                    _maxPrice >= _catalogMaxPrice
                        ? '\$${_maxPrice.round()}+'
                        : '\$${_maxPrice.round()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.black,
                  inactiveTrackColor: const Color(0xFFE5E5E5),
                  thumbColor: Colors.black,
                  overlayColor: Colors.black.withOpacity(0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _maxPrice.clamp(_catalogMinPrice, _catalogMaxPrice),
                  min: _catalogMinPrice,
                  max: _catalogMaxPrice,
                  onChanged: (v) => setState(() => _maxPrice = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${_catalogMinPrice.round()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '\$${_catalogMaxPrice.round()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Rating
              const Text(
                'Minimum Rating',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                children:
                    List.generate(5, (i) {
                        final star = i + 1;
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            star <= _minRating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFE53935),
                            size: 26,
                          ),
                          onPressed: () => setState(
                            () => _minRating = _minRating == star
                                ? 0
                                : star.toDouble(),
                          ),
                        );
                      }).expand((btn) sync* {
                        yield btn;
                        yield const SizedBox(width: 8);
                      }).toList()
                      ..removeLast(),
              ),
              const SizedBox(height: 24),

              // Sort by
              const Text(
                'Sort by',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 10),
              ..._sortOptions.map(
                (opt) => _SortTile(
                  label: opt.label,
                  selected: _sortKey == opt.value,
                  onTap: () => setState(() => _sortKey = opt.value),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortOption {
  final String label;
  final String value;
  const _SortOption(this.label, this.value);
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      shape: const StadiumBorder(),
      side: BorderSide.none,
    );
  }
}

/// Bordered row: label + trailing radio circle, matching the "Sort by" list
/// in the design (selected row gets a black border, filled radio dot).
class _SortTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.black : const Color(0xFFE5E5E5),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? Colors.black : Colors.grey.shade600,
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? Colors.black : Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
