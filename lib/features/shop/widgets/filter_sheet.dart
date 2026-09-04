import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/core/constants/categories.dart';
import 'package:yanzee_app/features/shop/provider/shop_provider.dart';

Future<void> showFilterSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(shopProvider).filters;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _FilterSheetContent(initial: current),
  );
}

class _FilterSheetContent extends ConsumerStatefulWidget {
  final ShopFilters initial;
  const _FilterSheetContent({required this.initial});

  @override
  ConsumerState<_FilterSheetContent> createState() =>
      _FilterSheetContentState();
}

class _FilterSheetContentState extends ConsumerState<_FilterSheetContent> {
  late String _category;
  late String _sortKey; // combined 'sortBy_order'
  late RangeValues _priceRange;
  late double _minRating;

  static const double _maxPriceBound =
      2000; // adjust to your catalog's realistic max

  @override
  void initState() {
    super.initState();
    _category = widget.initial.category;
    _sortKey = '${widget.initial.sortBy}_${widget.initial.order}';
    _priceRange = RangeValues(
      widget.initial.minPrice ?? 0,
      widget.initial.maxPrice ?? _maxPriceBound,
    );
    _minRating = widget.initial.minRating ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _category = 'all';
                  _sortKey = 'title_asc';
                  _priceRange = const RangeValues(0, _maxPriceBound);
                  _minRating = 0;
                }),
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Color(0xFFE53935)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
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
          const SizedBox(height: 20),

          const Text(
            'Price Range',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: _maxPriceBound,
            divisions: 40,
            activeColor: Colors.black,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          const SizedBox(height: 12),

          const Text(
            'Minimum Rating',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                icon: Icon(
                  star <= _minRating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFE53935),
                ),
                onPressed: () => setState(() => _minRating = star.toDouble()),
              );
            }),
          ),
          const SizedBox(height: 12),

          const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _sortKey,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'title_asc', child: Text('Name A-Z')),
              DropdownMenuItem(
                value: 'price_asc',
                child: Text('Price: Low-High'),
              ),
              DropdownMenuItem(
                value: 'price_desc',
                child: Text('Price: High-Low'),
              ),
              DropdownMenuItem(value: 'rating_desc', child: Text('Top Rated')),
            ],
            onChanged: (v) => setState(() => _sortKey = v!),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final parts = _sortKey.split('_');
                ref
                    .read(shopProvider.notifier)
                    .updateFilters(
                      ShopFilters(
                        category: _category,
                        sortBy: parts[0],
                        order: parts[1],
                        minPrice: _priceRange.start > 0
                            ? _priceRange.start
                            : null,
                        maxPrice: _priceRange.end < _maxPriceBound
                            ? _priceRange.end
                            : null,
                        minRating: _minRating > 0 ? _minRating : null,
                      ),
                    );
                Navigator.pop(context);
              },
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
    );
  }
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
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }
}
