import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/data/models/seller_models.dart';
import 'package:yanzee_app/data/models/shop_category.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_products_provider.dart';

// ===================================================================
// Shared widgets and colours used by the product form
// ===================================================================

const kPageBg = Color(0xFFF7F5F2);
const kFieldBg = Color(0xFFF5F4F1);

/// White rounded card with a thin border. It is a Material (not a plain
/// decorated Container) so ListTiles inside it can paint their splashes.
Widget _cardShell({required Widget child}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.ink.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, 
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kFieldBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppFonts.brand,
                        fontSize: Responsive.font(context, 15.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textGray,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// A card (or a plain row when [plain] is true) that opens and closes.
/// The fields inside keep their values while it is closed.
class CollapsibleCard extends StatefulWidget {
  const CollapsibleCard({super.key, 
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.plain = false,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool plain;
  final Widget child;

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final header = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _open = !_open),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: widget.plain ? 8 : 0),
        child: Row(
          children: [
            if (widget.icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kFieldBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 18, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: widget.plain
                        ? const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)
                        : TextStyle(
                            fontFamily: AppFonts.brand,
                            fontSize: Responsive.font(context, 15.5),
                            fontWeight: FontWeight.bold,
                          ),
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textGray,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        ),
      ),
    );

    final body = AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: _open
          ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: widget.child,
            )
          : const SizedBox(width: double.infinity, height: 0),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [header, body],
    );

    if (widget.plain) return content;

    return _cardShell(child: content);
  }
}

class AddMediaRow extends StatelessWidget {
  const AddMediaRow({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kFieldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.gallery_add, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Media',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Add photos for this product',
                    style: TextStyle(fontSize: 12, color: AppColors.textGray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGray),
          ],
        ),
      ),
    );
  }
}

class ChoiceBox extends StatelessWidget {
  const ChoiceBox({super.key, 
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.ink : Colors.grey.shade300,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? AppColors.ink : Colors.grey,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlackChip extends StatelessWidget {
  const BlackChip({super.key, required this.label, required this.onRemove});

  final String label;
  final VoidCallback? onRemove; // null = no X button

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 12, right: onRemove == null ? 12 : 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kFieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textGray),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ---- colour helpers ----------------------------------------------------

final RegExp _hexRule = RegExp(r'^#([0-9a-f]{3}|[0-9a-f]{6})$');

/// "#FFF" or "#FFFFFF" -> "#ffffff". Returns null if it is not a hex code.
String? normalizeHex(String raw) {
  final t = raw.trim().toLowerCase();
  if (!_hexRule.hasMatch(t)) return null;
  if (t.length == 4) return '#${t[1]}${t[1]}${t[2]}${t[2]}${t[3]}${t[3]}';
  return t;
}

Color hexToColor(String hex) {
  final n = normalizeHex(hex);
  if (n == null) return Colors.grey;
  return Color(int.parse('FF${n.substring(1)}', radix: 16));
}

String colorToHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

// ---- variant colour picker --------------------------------------------

/// Shows the chosen colours and an "Add colour" button that opens the colour
/// picker. The chosen colour is stored as a hex code (for example #ff7f50),
/// which is exactly what the backend receives.
class VariantColorPicker extends StatelessWidget {
  const VariantColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected; // hex codes
  final ValueChanged<List<String>> onChanged;

  void _remove(String hex) => onChanged([...selected]..remove(hex));

  Future<void> _openPicker(BuildContext context) async {
    var temp = const Color(0xFF3366CC);
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a colour'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            hexInputBar: true,
            labelTypes: const [],
            portraitOnly: true,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(temp),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    final hex = colorToHex(picked);
    if (!selected.contains(hex)) onChanged([...selected, hex]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hex in selected)
                  ColorChip(hex: hex, onRemove: () => _remove(hex)),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _openPicker(context),
          icon: const Icon(Icons.palette_outlined, size: 18),
          label: const Text('Add colour'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

/// A chosen colour: a small swatch, its hex code, and an X to remove it.
class ColorChip extends StatelessWidget {
  const ColorChip({super.key, required this.hex, required this.onRemove});

  final String hex;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 6, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: hexToColor(hex),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 8),
          Text(hex, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }
}

// ---- dropdowns --------------------------------------------------------

ButtonStyleData formButtonStyle() => ButtonStyleData(
      height: 48,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: kFieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
    );

IconStyleData formIconStyle() => const IconStyleData(
      icon: Icon(Icons.keyboard_arrow_down_rounded),
      openMenuIcon: Icon(Icons.keyboard_arrow_up_rounded),
      iconSize: 22,
    );

DropdownStyleData formDropStyle(double maxHeight) => DropdownStyleData(
      maxHeight: maxHeight,
      elevation: 6,
      padding: const EdgeInsets.symmetric(vertical: 6),
      offset: const Offset(0, -2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(40),
        thickness: WidgetStateProperty.all(4),
      ),
    );

/// Menu height: about 38% of the screen, kept between 160 and 280.
double formMenuHeight(BuildContext context) =>
    (MediaQuery.sizeOf(context).height * 0.38).clamp(160.0, 280.0).toDouble();

Widget formItemText(String text) => Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14),
    );

/// Grey box shown while loading or when there is nothing to pick.
class FormDisabledField extends StatelessWidget {
  const FormDisabledField(this.text, {super.key, this.loading = false});

  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: kFieldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textGray),
              ),
            ),
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      );
}

/// Red box with the error text and a Retry button.
class FormErrorField extends StatelessWidget {
  const FormErrorField(this.message, this.onRetry, {super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 14, right: 4, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.red.shade800),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

/// Single-choice dropdown (brand, audience).
class FormDropdown<T> extends StatelessWidget {
  const FormDropdown({
    super.key,
    required this.notifier,
    required this.hint,
    required this.items,
  });

  final ValueNotifier<T?> notifier;
  final String hint;
  final List<DropdownItem<T>> items;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: true,
        hint: Text(
          hint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: AppColors.textGray),
        ),
        items: items,
        valueListenable: notifier,
        onChanged: (v) => notifier.value = v,
        buttonStyleData: formButtonStyle(),
        iconStyleData: formIconStyle(),
        dropdownStyleData: formDropStyle(formMenuHeight(context)),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

/// Multi-select categories with checkboxes and removable chips below.
class CategoryMultiSelect extends StatelessWidget {
  const CategoryMultiSelect({
    super.key,
    required this.categories,
    required this.names,
    required this.notifier,
  });

  final List<ShopCategory> categories;

  /// id -> name, including categories the product has but the list lacks.
  final Map<String, String> names;
  final ValueNotifier<List<String>> notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            isExpanded: true,
            hint: const Text(
              'Select categories',
              style: TextStyle(fontSize: 14, color: AppColors.textGray),
            ),
            items: [
              for (final c in categories)
                DropdownItem<String>(
                  value: c.id,
                  height: 44,
                  closeOnTap: false,
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: notifier,
                    builder: (context, selected, _) {
                      final on = selected.contains(c.id);
                      return Container(
                        height: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Icon(
                              on
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 20,
                              color: on ? AppColors.ink : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      on ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
            multiValueListenable: notifier,
            onChanged: (value) {
              if (value == null) return;
              final cur = notifier.value;
              notifier.value = cur.contains(value)
                  ? ([...cur]..remove(value))
                  : [...cur, value];
            },
            selectedItemBuilder: (context) => [
              for (final _ in categories)
                ValueListenableBuilder<List<String>>(
                  valueListenable: notifier,
                  builder: (context, selected, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      selected.isEmpty
                          ? 'Select categories'
                          : '${selected.length} selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: selected.isEmpty
                            ? AppColors.textGray
                            : AppColors.ink,
                      ),
                    ),
                  ),
                ),
            ],
            buttonStyleData: formButtonStyle(),
            iconStyleData: formIconStyle(),
            dropdownStyleData: formDropStyle(formMenuHeight(context)),
            menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.zero),
          ),
        ),
        ValueListenableBuilder<List<String>>(
          valueListenable: notifier,
          builder: (context, selected, _) {
            if (selected.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in selected)
                    BlackChip(
                      label: names[id] ?? 'Category',
                      onRemove: () => notifier.value = [...selected]..remove(id),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---- photos and SEO image ---------------------------------------------

/// Horizontal row of product photos with a "+" tile at the end.
class ProductImagesRow extends StatelessWidget {
  const ProductImagesRow({
    super.key,
    required this.images,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ProductImageEntry> images;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = ((width - 32 - 32 - 24) / 3).clamp(84.0, 120.0).toDouble();
    return SizedBox(
      height: size,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < images.length; i++) _tile(i, size),
          GestureDetector(
            onTap: enabled ? onAdd : null,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: kFieldBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(int index, double size) {
    final entry = images[index];
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: kFieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          entry.file != null
              ? Image.file(entry.file!, fit: BoxFit.cover)
              : Image.network(
                  entry.url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade200),
                ),
          if (index == 0)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Cover',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          Positioned(
            right: 4,
            top: 4,
            child: InkWell(
              onTap: enabled ? () => onRemove(index) : null,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Square tile for the SEO image: shows the picked file or saved URL.
class SeoImageTile extends StatelessWidget {
  const SeoImageTile({
    super.key,
    required this.picked,
    required this.url,
    required this.enabled,
    required this.onTap,
  });

  final File? picked;
  final String? url;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = picked != null || (url?.isNotEmpty ?? false);
    final size = Responsive.isSmallPhone(context) ? 110.0 : 130.0;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: kFieldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  picked != null
                      ? Image.file(picked!, fit: BoxFit.cover)
                      : Image.network(
                          url!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade200),
                        ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.55),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: const Text(
                        'Replace',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.gallery_add, color: AppColors.textGray),
                  SizedBox(height: 6),
                  Text('Add image', style: TextStyle(fontSize: 12)),
                ],
              ),
      ),
    );
  }
}

// ---- date and similar-products pickers ---------------------------------

/// Read-only box that shows a date; tap to pick, X to clear.
class ReleaseDateField extends StatelessWidget {
  const ReleaseDateField({
    super.key,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final d = date;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: kFieldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                d == null ? 'Not set' : d.toIso8601String().substring(0, 10),
                style: TextStyle(
                  fontSize: 14,
                  color: d == null ? AppColors.textGray : AppColors.ink,
                ),
              ),
            ),
            if (d != null)
              InkWell(onTap: onClear, child: const Icon(Icons.close, size: 18))
            else
              const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to tick similar products. Returns the chosen ids,
/// or null if the sheet was closed without pressing Done.
Future<List<String>?> showSimilarProductsSheet(
  BuildContext context, {
  required List<SellerProduct> candidates,
  required List<String> selected,
}) async {
  final chosen = {...selected};
  final result = await showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Similar products',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in candidates)
                    CheckboxListTile(
                      value: chosen.contains(p.id),
                      title: Text(p.name),
                      activeColor: AppColors.ink,
                      onChanged: (v) => setSheet(() {
                        if (v == true) {
                          chosen.add(p.id);
                        } else {
                          chosen.remove(p.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(chosen),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result?.toList();
}