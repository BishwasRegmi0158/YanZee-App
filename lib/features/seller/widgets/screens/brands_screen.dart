import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/brand.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_brands_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_toggle.dart';

class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  String _query = '';

  void _openForm({Brand? initial}) {
    if (initial == null) {
      context.push('/seller/brands/add');
    } else {
      context.push('/seller/brands/edit', extra: initial);
    }
  }

  Future<void> _toggle(Brand brand) async {
    final error = await ref.read(sellerBrandsProvider.notifier).toggle(brand);
    if (error != null && mounted) AppToast.error(context, error);
  }

  Future<void> _confirmDelete(Brand brand) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete brand?'),
        content: Text(
          '"${brand.name}" will be removed. This can\'t be undone.',
        ),
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

    final error = await ref
        .read(sellerBrandsProvider.notifier)
        .deleteBrand(brand);
    if (!mounted) return;
    AppToast.result(
      context,
      error: error,
      success: '"${brand.name}" deleted successfully',
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(sellerBrandsProvider);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Brands')),
        bottomNavigationBar: SellerBottomBar(
          label: 'Add brand',
          saving: false,
          onPressed: () => _openForm(),
        ),
        body: brandsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: e.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(sellerBrandsProvider),
          ),
          data: (brands) {
            final sorted = [...brands]
              ..sort(
                (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                  a.createdAt ?? DateTime(0),
                ),
              );
            final q = _query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? sorted
                : sorted
                      .where((b) => b.name.toLowerCase().contains(q))
                      .toList();

            return RefreshIndicator(
              onRefresh: () => ref.refresh(sellerBrandsProvider.future),
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
                      hintText: 'Search brands',
                      prefixIcon: Icon(Iconsax.search_normal_1, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${brands.length} brand${brands.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    _EmptyView(
                      text: brands.isEmpty
                          ? 'No brands yet.\nTap "Add brand" to create one.'
                          : 'No brands match "$_query"',
                    )
                  else
                    for (var i = 0; i < filtered.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SellerReveal(
                          index: i < 6 ? i : 6,
                          child: _BrandCard(
                            brand: filtered[i],
                            onTap: () => context.push(
                              '/seller/brands/detail',
                              extra: filtered[i],
                            ),
                            onToggle: () => _toggle(filtered[i]),
                            onEdit: () => _openForm(initial: filtered[i]),
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

class _BrandCard extends StatelessWidget {
  const _BrandCard({
    required this.brand,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Brand brand;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final created = brand.createdAt == null
        ? null
        : _dateFmt.format(brand.createdAt!.toLocal());

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
              _BrandLogo(url: brand.logo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (created != null) 'Created $created',
                        '${brand.productCount} product${brand.productCount == 1 ? '' : 's'}',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      brand.isAvailable ? 'Available' : 'Hidden',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: brand.isAvailable
                            ? const Color(0xFF2E9E2E)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SellerToggle(
                value: brand.isAvailable,
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
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: scheme.error),
                    ),
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

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget placeholder() => Container(
      width: 56,
      height: 56,
      color: scheme.surfaceContainerHighest,
      child: Icon(Iconsax.tag, color: scheme.onSurfaceVariant),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: (url == null || url!.isEmpty)
          ? placeholder()
          : Image.network(
              url!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              cacheWidth: 168,
              errorBuilder: (_, __, ___) => placeholder(),
            ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Iconsax.tag, size: 44, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}