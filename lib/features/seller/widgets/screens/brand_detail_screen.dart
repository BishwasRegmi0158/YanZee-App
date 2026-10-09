import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/data/models/brand.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_brands_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_toggle.dart';

class BrandDetailScreen extends ConsumerWidget {
  const BrandDetailScreen({super.key, required this.brand});

  final Brand brand;

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, Brand b) async {
    final error = await ref.read(sellerBrandsProvider.notifier).toggle(b);
    if (error != null && context.mounted) _snack(context, error);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Brand b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete brand?'),
        content: Text('"${b.name}" will be removed. This can\'t be undone.'),
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
    if (ok != true || !context.mounted) return;

    final error = await ref.read(sellerBrandsProvider.notifier).deleteBrand(b);
    if (!context.mounted) return;
    _snack(context, error ?? '"${b.name}" deleted');
    if (error == null) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the live copy so the switch and edits show up here at once.
    Brand live = brand;
    final list = ref.watch(sellerBrandsProvider).value;
    if (list != null) {
      for (final b in list) {
        if (b.id == brand.id) live = b;
      }
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final created = live.createdAt == null
        ? null
        : _dateFmt.format(live.createdAt!.toLocal());
    final description = live.description?.trim() ?? '';
    final hasSeo =
        (live.seoTitle?.trim().isNotEmpty ?? false) ||
        (live.seoImage?.trim().isNotEmpty ?? false);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Brand details')),
        bottomNavigationBar: SellerBottomBar(
          label: 'Edit brand',
          saving: false,
          onPressed: () => context.push('/seller/brands/edit', extra: live),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SellerReveal(
              index: 0,
              child: Column(
                children: [
                  SellerDetailAvatar(url: live.logo, icon: Iconsax.tag),
                  const SizedBox(height: 12),
                  Text(
                    live.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SellerStatusPill(
                    text: live.isAvailable ? 'Available' : 'Hidden',
                    positive: live.isAvailable,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SellerReveal(
              index: 1,
              child: SellerSectionCard(
                icon: Iconsax.info_circle,
                title: 'Details',
                child: Column(
                  children: [
                    SellerInfoRow(label: 'Name', value: live.name),
                    SellerInfoRow(label: 'Slug', value: live.slug),
                    SellerInfoRow(label: 'Created', value: created),
                    SellerInfoRow(
                      label: 'Products',
                      value: '${live.productCount}',
                      last: true,
                    ),
                  ],
                ),
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 16),
              SellerReveal(
                index: 2,
                child: SellerSectionCard(
                  icon: Iconsax.document_text,
                  title: 'Description',
                  child: Text(description, style: theme.textTheme.bodyMedium),
                ),
              ),
            ],
            if (hasSeo) ...[
              const SizedBox(height: 16),
              SellerReveal(
                index: 3,
                child: SellerSectionCard(
                  icon: Iconsax.search_normal_1,
                  title: 'SEO',
                  child: Column(
                    children: [
                      SellerInfoRow(label: 'SEO title', value: live.seoTitle),
                      SellerInfoRow(
                        label: 'SEO image',
                        value: (live.seoImage?.isNotEmpty ?? false)
                            ? 'Added'
                            : null,
                        last: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SellerReveal(
              index: 4,
              child: SellerSectionCard(
                icon: Iconsax.eye,
                title: 'Visibility',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Available to customers',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  trailing: SellerToggle(
                    value: live.isAvailable,
                    onChanged: (_) => _toggle(context, ref, live),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _delete(context, ref, live),
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              icon: const Icon(Iconsax.trash, size: 18),
              label: const Text('Delete brand'),
            ),
          ],
        ),
      ),
    );
  }
}
