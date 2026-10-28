import 'package:flutter/material.dart';

/// A horizontally scrolling row of choice chips. Each option is
/// (label, value); a null value means "no filter".
class SellerFilterChips extends StatelessWidget {
  const SellerFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String?)> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (label, value) in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == value,
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected == value ? scheme.onPrimary : scheme.onSurface,
                ),
                onSelected: (_) => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }
}