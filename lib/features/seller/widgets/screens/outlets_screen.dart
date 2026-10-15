import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';

const _pageBg = Color(0xFFF7F5F2);

class OutletsScreen extends ConsumerStatefulWidget {
  const OutletsScreen({super.key});

  @override
  ConsumerState<OutletsScreen> createState() => _OutletsScreenState();
}

class _OutletsScreenState extends ConsumerState<OutletsScreen> {
  String _query = '';
  final _statusFilter = ValueNotifier<String?>('all');

  @override
  void dispose() {
    _statusFilter.dispose();
    super.dispose();
  }

  bool get _filtersActive => (_statusFilter.value ?? 'all') != 'all';

  void _clearFilters() {
    _statusFilter.value = 'all';
    setState(() => _query = '');
  }

  void _snack(String message, {bool failed = false}) {
    if (failed) {
      AppToast.error(context, message);
    } else {
      AppToast.success(context, message);
    }
  }

  Future<void> _toggle(Outlet o) async {
    final error = await ref.read(sellerOutletsProvider.notifier).toggle(o);
    if (!mounted) return;
    _snack(
      error ?? '"${o.name}" ${o.isActive ? 'deactivated' : 'activated'}',
      failed: error != null,
    );
  }

  Future<void> _confirmDelete(Outlet o) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete outlet'),
        content: Text('Remove "${o.name}"? This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final error = await ref.read(sellerOutletsProvider.notifier).delete(o);
      if (!mounted) return;
      _snack(error ?? '"${o.name}" deleted', failed: error != null);
    }
  }

  List<Outlet> _apply(List<Outlet> all) {
    final q = _query.trim().toLowerCase();
    final status = _statusFilter.value ?? 'all';
    final sorted = [...all]
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    return sorted.where((o) {
      if (status == 'active' && !o.isActive) return false;
      if (status == 'inactive' && o.isActive) return false;
      if (q.isEmpty) return true;
      return o.name.toLowerCase().contains(q) ||
          (o.address ?? '').toLowerCase().contains(q) ||
          (o.contactPerson ?? '').toLowerCase().contains(q) ||
          (o.contactPhone ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final outletsAsync = ref.watch(sellerOutletsProvider);
    final isNarrow = Responsive.isSmallPhone(context);

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: _HeaderRow(
                isNarrow: isNarrow,
                onBack: () => Navigator.of(context).maybePop(),
                onAdd: () => context.push('/seller/outlets/add'),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search outlets',
                  prefixIcon: const Icon(
                    Iconsax.search_normal_1,
                    size: 20,
                    color: AppColors.textGray,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.ink),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _statusDropdown(),
            ),
            Expanded(
              child: outletsAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Failed to load outlets: ${e.toString().replaceFirst('Exception: ', '')}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(sellerOutletsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (outlets) => _buildList(outlets),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Outlet> outlets) {
    final filtered = _apply(outlets);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(sellerOutletsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  filtered.length == outlets.length
                      ? '${outlets.length} outlet${outlets.length == 1 ? '' : 's'}'
                      : '${filtered.length} of ${outlets.length} outlets',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ),
              if (_filtersActive || _query.isNotEmpty)
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Iconsax.location, size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    outlets.isEmpty && !_filtersActive
                        ? 'No outlets yet'
                        : 'No outlets match your filters',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textGray),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.ink.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < filtered.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: Colors.grey.shade200,
                      ),
                    _OutletRow(
                      outlet: filtered[i],
                      onTap: () => context.push(
                        '/seller/outlets/detail',
                        extra: filtered[i],
                      ),
                      onEdit: () => context.push(
                        '/seller/outlets/edit',
                        extra: filtered[i],
                      ),
                      onToggle: () => _toggle(filtered[i]),
                      onDelete: () => _confirmDelete(filtered[i]),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  //  filter dropdown

  Widget _statusDropdown() {
    final items = <DropdownItem<String>>[
      _filterItem('all', 'All statuses'),
      _filterItem('active', 'Active'),
      _filterItem('inactive', 'Inactive'),
    ];
    return _filterDropdown(
      items: items,
      notifier: _statusFilter,
      onChanged: (v) {
        _statusFilter.value = v ?? 'all';
        setState(() {});
      },
    );
  }

  DropdownItem<String> _filterItem(String value, String label) =>
      DropdownItem<String>(
        value: value,
        height: 42,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5),
        ),
      );

  Widget _filterDropdown({
    required List<DropdownItem<String>> items,
    required ValueNotifier<String?> notifier,
    required ValueChanged<String?> onChanged,
  }) {
    final maxH = (MediaQuery.sizeOf(context).height * 0.38).clamp(160.0, 280.0);
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        items: items,
        valueListenable: notifier,
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 42,
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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

class _HeaderRow extends StatelessWidget {
  final bool isNarrow;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  const _HeaderRow({
    required this.isNarrow,
    required this.onBack,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final backButton = IconButton(
      onPressed: onBack,
      tooltip: 'Back',
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 20,
        color: AppColors.ink,
      ),
    );

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outlets',
          style: TextStyle(
            fontFamily: AppFonts.brand,
            fontSize: Responsive.font(context, 24),
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Manage where you sell and store stock',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: Responsive.font(context, 12),
            color: AppColors.textGray,
          ),
        ),
      ],
    );

    final addButton = ElevatedButton.icon(
      onPressed: onAdd,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Iconsax.add, size: 18),
      label: Text(
        'Add',
        style: TextStyle(fontSize: Responsive.font(context, 13)),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              backButton,
              Expanded(child: title),
            ],
          ),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.only(left: 8), child: addButton),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        backButton,
        Expanded(child: title),
        const SizedBox(width: 12),
        addButton,
      ],
    );
  }
}

class _OutletRow extends StatelessWidget {
  final Outlet outlet;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _OutletRow({
    required this.outlet,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = outlet.isActive;
    final bg = active ? const Color(0xFFDDF5DD) : Colors.grey.shade200;
    final fg = active ? const Color(0xFF1E8E3E) : Colors.grey.shade700;
    final contact = [
      outlet.contactPerson,
      outlet.contactPhone,
    ].whereType<String>().join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.location, color: AppColors.textGray),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: fg,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              active ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: Responsive.font(context, 10.5),
                                fontWeight: FontWeight.w600,
                                color: fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (outlet.isMain)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Main',
                            style: TextStyle(
                              fontSize: Responsive.font(context, 10.5),
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    outlet.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: Responsive.font(context, 14.5),
                      color: AppColors.ink,
                    ),
                  ),
                  if (outlet.address != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      outlet.address!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.font(context, 12),
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.font(context, 11.5),
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert, size: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    onEdit();
                  case 'toggle':
                    onToggle();
                  default:
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(active ? 'Deactivate' : 'Activate'),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}