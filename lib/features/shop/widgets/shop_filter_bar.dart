import 'package:flutter/material.dart';
import 'package:yanzee_app/core/constants/categories.dart';
import 'package:yanzee_app/features/shop/provider/shop_provider.dart';

class ShopFilterBar extends StatelessWidget {
  final ShopFilters filters;
  final ValueChanged<ShopFilters> onChanged;

  const ShopFilterBar({super.key, required this.filters, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: filters.category,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                ...categoryLabels.map(
                  (label) => DropdownMenuItem(
                    value: categorySlugMap[label], // slug is the real value sent to the API
                    child: Text(label),             // label is what the user sees
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(filters.copyWith(category: v));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: '${filters.sortBy}_${filters.order}',
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'title_asc', child: Text('Name A-Z')),
                DropdownMenuItem(value: 'price_asc', child: Text('Price: Low-High')),
                DropdownMenuItem(value: 'price_desc', child: Text('Price: High-Low')),
                DropdownMenuItem(value: 'rating_desc', child: Text('Top Rated')),
              ],
              onChanged: (v) {
                if (v == null) return;
                final parts = v.split('_');
                onChanged(filters.copyWith(sortBy: parts[0], order: parts[1]));
              },
            ),
          ),
        ],
      ),
    );
  }
}