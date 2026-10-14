import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';

class OutletsScreen extends ConsumerStatefulWidget {
  const OutletsScreen({super.key});

  @override
  ConsumerState<OutletsScreen> createState() => _OutletsScreenState();
}

class _OutletsScreenState extends ConsumerState<OutletsScreen> {
  String _query = '';

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle(Outlet o) async {
    final error = await ref.read(sellerOutletsProvider.notifier).toggle(o);
    if (error != null && mounted) _snack(error);
  }

  Future<void> _confirmDelete(Outlet o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete outlet?'),
        content: Text('"${o.name}" will be removed. This can\'t be undone.'),
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
    final error = await ref.read(sellerOutletsProvider.notifier).delete(o);
    if (!mounted) return;
    _snack(error ?? '"${o.name}" deleted');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sellerOutletsProvider);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Outlets')),
        bottomNavigationBar: SellerBottomBar(
          label: 'Add outlet',
          saving: false,
          onPressed: () => context.push('/seller/outlets/add'),
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
                    onPressed: () => ref.invalidate(sellerOutletsProvider),
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
                : sorted
                    .where(
                      (o) =>
                          o.name.toLowerCase().contains(q) ||
                          (o.address ?? '').toLowerCase().contains(q),
                    )
                    .toList();
            final theme = Theme.of(context);

            return RefreshIndicator(
              onRefresh: () => ref.refresh(sellerOutletsProvider.future),
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
                      hintText: 'Search outlets',
                      prefixIcon: Icon(Iconsax.search_normal_1, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${items.length} outlet${items.length == 1 ? '' : 's'}',
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
                              ? 'No outlets yet.\nTap "Add outlet" to create one.'
                              : 'No outlets match "$_query"',
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
                          child: _OutletCard(
                            outlet: filtered[i],
                            onTap: () => context.push(
                              '/seller/outlets/detail',
                              extra: filtered[i],
                            ),
                            onToggle: () => _toggle(filtered[i]),
                            onEdit: () => context.push(
                              '/seller/outlets/edit',
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

class _OutletCard extends StatelessWidget {
  const _OutletCard({
    required this.outlet,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Outlet outlet;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final created = outlet.createdAt == null
        ? null
        : _dateFmt.format(outlet.createdAt!.toLocal());

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
              const SellerDetailAvatar(
                url: null,
                icon: Iconsax.location,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outlet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (outlet.address != null) outlet.address!,
                        if (created != null) 'Created $created',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          outlet.isActive ? 'Active' : 'Inactive',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: outlet.isActive
                                ? const Color(0xFF2E9E2E)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        if (outlet.isMain) ...[
                          const SizedBox(width: 8),
                          const SellerStatusPill(text: 'Main', positive: true),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: outlet.isActive,
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