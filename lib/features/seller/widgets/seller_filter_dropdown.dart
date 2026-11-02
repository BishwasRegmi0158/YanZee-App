import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';

/// A white, rounded dropdown for filters (same look as the Products page).
/// [options] are (label, value) pairs. Use the value 'all' for "no filter".
class SellerFilterDropdown extends StatelessWidget {
  const SellerFilterDropdown({
    super.key,
    required this.options,
    required this.notifier,
    required this.onChanged,
  });

  final List<(String, String)> options;
  final ValueNotifier<String?> notifier;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxH = (MediaQuery.sizeOf(context).height * 0.38).clamp(160.0, 280.0);

    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        items: <DropdownItem<String>>[
          for (final (label, value) in options)
            DropdownItem<String>(
              value: value,
              height: 42,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
        ],
        valueListenable: notifier,
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 42,
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.rXl),
            border: Border.all(color: colors.outline),
          ),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.keyboard_arrow_down_rounded),
          openMenuIcon: Icon(Icons.keyboard_arrow_up_rounded),
          iconSize: 20,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: maxH.toDouble(),
          elevation: 6,
          padding: const EdgeInsets.symmetric(vertical: 6),
          offset: const Offset(0, -2),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.rXl),
            border: Border.all(color: colors.outlineVariant),
          ),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: WidgetStateProperty.all(4),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}