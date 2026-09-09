import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

class SearchableSelectField extends StatelessWidget {
  const SearchableSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.placeholder,
    this.enabled = true,
    this.disabledPlaceholder,
    this.required = false,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String placeholder;
  final bool enabled;
  final String? disabledPlaceholder;
  final bool required;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _SearchableSelectSheet(
        title: label,
        options: options,
        initialValue: value,
      ),
    );
    if (selected != null) {
      onChanged(selected.isEmpty ? null : selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = value ?? (enabled ? placeholder : disabledPlaceholder ?? placeholder);
    final isPlaceholder = value == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: AuthTextStyles.fieldLabel,
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(text: ' *', style: TextStyle(color: AuthColors.required)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? () => _openPicker(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFF5F4F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AuthColors.borderDefault),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isPlaceholder ? const Color(0xFFB0AEA9) : AuthColors.textDark,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: enabled ? AuthColors.iconMuted : const Color(0xFFCFCDC9),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchableSelectSheet extends StatefulWidget {
  const _SearchableSelectSheet({
    required this.title,
    required this.options,
    required this.initialValue,
  });

  final String title;
  final List<String> options;
  final String? initialValue;

  @override
  State<_SearchableSelectSheet> createState() => _SearchableSelectSheetState();
}

class _SearchableSelectSheetState extends State<_SearchableSelectSheet> {
  late final TextEditingController _searchController;
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = widget.options;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? widget.options
          : widget.options
              .where((o) => o.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (widget.initialValue != null)
                    TextButton(
                      onPressed: () => Navigator.pop(context, ''),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: authInputDecoration(
                  hint: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: AuthColors.iconMuted),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('No matches found.'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final option = _filtered[index];
                        final isSelected = option == widget.initialValue;
                        return ListTile(
                          title: Text(option),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.black)
                              : null,
                          onTap: () => Navigator.pop(context, option),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}