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
    this.icon = Icons.location_on_rounded,
    this.showLabel = true,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String placeholder;
  final bool enabled;
  final String? disabledPlaceholder;
  final bool required;

  /// Leading icon inside the pill.
  final IconData icon;

  /// Small label above the pill. Set to false to show only the placeholder,
  /// like the plain text fields.
  final bool showLabel;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AuthColors.screenBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
    final displayText =
        value ?? (enabled ? placeholder : (disabledPlaceholder ?? placeholder));
    final isPlaceholder = value == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AuthColors.pillText,
                ),
                children: [
                  TextSpan(text: label),
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AuthColors.required),
                    ),
                ],
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: enabled ? authPillShadow : null,
          ),
          child: Material(
            color: enabled ? Colors.white : const Color(0xFFEDEFF1),
            borderRadius: BorderRadius.circular(40),
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: enabled ? () => _openPicker(context) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: enabled
                          ? AuthColors.pillIcon
                          : const Color(0xFFB8BCC0),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: isPlaceholder
                              ? AuthColors.pillHint
                              : AuthColors.pillText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: enabled
                          ? AuthColors.pillIcon
                          : const Color(0xFFB8BCC0),
                    ),
                  ],
                ),
              ),
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
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.options
          : widget.options.where((o) => o.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final height = MediaQuery.sizeOf(context).height * 0.7;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D8DC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (widget.initialValue != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AuthColors.primary,
                        ),
                        onPressed: () => Navigator.pop(context, ''),
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: authPillShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AuthColors.pillText,
                    ),
                    decoration: authPillInputDecoration(
                      hint: 'Search...',
                      icon: Icons.search_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No matches found.',
                          style: TextStyle(color: AuthColors.subtitleGray),
                        ),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final option = _filtered[index];
                          final isSelected = option == widget.initialValue;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 28,
                            ),
                            title: Text(
                              option,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: AuthColors.pillText,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: AuthColors.primary,
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, option),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}