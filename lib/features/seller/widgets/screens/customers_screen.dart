import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/customer.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_customers_provider.dart';

const _pageBg = Color(0xFFF7F5F2);

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 300) {
      ref.read(sellerCustomersProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // shows or hides the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(customerSearchProvider.notifier).state = value.trim();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    ref.read(customerSearchProvider.notifier).state = '';
    setState(() {});
  }

  void _snack(String message, {bool failed = false}) {
    if (failed) {
      AppToast.error(context, message);
    } else {
      AppToast.success(context, message);
    }
  }

  Future<void> _confirmDelete(Customer c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete customer'),
        content: Text('Remove "${c.name}"? This can\'t be undone.'),
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
      final error =
          await ref.read(sellerCustomersProvider.notifier).delete(c);
      if (!mounted) return;
      _snack(error ?? '"${c.name}" deleted', failed: error != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(sellerCustomersProvider);
    final query = ref.watch(customerSearchProvider);
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
                onAdd: () => context.push('/seller/customers/add'),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone or email',
                  prefixIcon: const Icon(
                    Iconsax.search_normal_1,
                    size: 20,
                    color: AppColors.textGray,
                  ),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close, size: 18),
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
            Expanded(
              child: customersAsync.when(
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
                          'Failed to load customers: ${e.toString().replaceFirst('Exception: ', '')}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(sellerCustomersProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (s) => _buildList(s, query),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(CustomersState s, String query) {
    final items = s.items;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(sellerCustomersProvider.future),
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            '${s.totalCount} customer${s.totalCount == 1 ? '' : 's'}'
            '${query.isEmpty ? '' : ' found'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textGray),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Iconsax.user, size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    query.isEmpty
                        ? 'No customers yet'
                        : 'No customers match "$query"',
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
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: Colors.grey.shade200,
                      ),
                    _CustomerRow(
                      customer: items[i],
                      onTap: () => context.push(
                        '/seller/customers/edit',
                        extra: items[i],
                      ),
                      onEdit: () => context.push(
                        '/seller/customers/edit',
                        extra: items[i],
                      ),
                      onDelete: () => _confirmDelete(items[i]),
                    ),
                  ],
                ],
              ),
            ),
          if (s.loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
        ],
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
          'Customers',
          style: TextStyle(
            fontFamily: AppFonts.brand,
            fontSize: Responsive.font(context, 24),
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'People who buy from your store',
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
          Row(children: [backButton, Expanded(child: title)]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: addButton,
          ),
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

class _CustomerRow extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerRow({
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  static final _dateFmt = DateFormat('dd MMM yyyy');

  String get _initial {
    final n = customer.name.trim();
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final created = customer.createdAt == null
        ? null
        : _dateFmt.format(customer.createdAt!.toLocal());

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Text(
                _initial,
                style: TextStyle(
                  fontSize: Responsive.font(context, 17),
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: Responsive.font(context, 14.5),
                      color: AppColors.ink,
                    ),
                  ),
                  if (customer.phone != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      customer.phone!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.font(context, 12.5),
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                  if (customer.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      customer.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.font(context, 12.5),
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                  if (created != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Added $created',
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
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuDivider(height: 1),
                PopupMenuItem(
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