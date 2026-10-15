import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/shop_category.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_categories_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _query = '';

  Future<void> _toggle(ShopCategory c) async {
    final error = await ref.read(sellerCategoriesProvider.notifier).toggle(c);
    if (error != null && mounted) AppToast.error(context, error);
  }

  Future<void> _confirmDelete(ShopCategory c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('"${c.name}" will be removed. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await ref.read(sellerCategoriesProvider.notifier).delete(c);
    if (!mounted) return;
    AppToast.result(
      context,
      error: error,
      success: '"${c.name}" deleted successfully',
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sellerCategoriesProvider);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        bottomNavigationBar: SellerBottomBar(
          label: 'Add category',
          saving: false,
          onPressed: () => context.push('/seller/categories/add'),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(sellerCategoriesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            final sorted = [...items]..sort(
                (a, b) => (b.createdAt ?? DateTime(0))
                    .compareTo(a.createdAt ?? DateTime(0)),
              );
            final q = _query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? sorted
                : sorted.where((c) => c.name.toLowerCase().contains(q)).toList();
            final theme = Theme.of(context);

            return RefreshIndicator(
              onRefresh: () => ref.refresh(sellerCategoriesProvider.future),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search categories',
                      prefixIcon: Icon(Iconsax.search_normal_1, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${items.length} categor${items.length == 1 ? 'y' : 'ies'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          items.isEmpty
                              ? 'No categories yet.\nTap "Add category" to create one.'
                              : 'No categories match "$_query"',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < filtered.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SellerReveal(
                          index: i < 6 ? i : 6,
                          child: _CategoryCard(
                            category: filtered[i],
                            onTap: () => context.push(
                              '/seller/categories/detail',
                              extra: filtered[i],
                            ),
                            onToggle: () => _toggle(filtered[i]),
                            onEdit: () => context.push(
                              '/seller/categories/edit',
                              extra: filtered[i],
                            ),
                            onDelete: () => _confirmDelete(filtered[i]),
                          ),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopCategory category;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final created = category.createdAt == null
        ? null
        : _dateFmt.format(category.createdAt!.toLocal());
    final n = category.productCount;

    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              SellerDetailAvatar(
                url: category.image,
                icon: Iconsax.category,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (created != null) 'Created $created',
                        '$n product${n == 1 ? '' : 's'}',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.isAvailable ? 'Available' : 'Hidden',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: category.isAvailable
                            ? const Color(0xFF2E9E2E)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: category.isAvailable,
                onChanged: (_) => onToggle(),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: scheme.error)),
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