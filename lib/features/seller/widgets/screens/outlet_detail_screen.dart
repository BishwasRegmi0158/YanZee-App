import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/seller_toggle.dart';

class OutletDetailScreen extends ConsumerWidget {
  const OutletDetailScreen({super.key, required this.outlet});

  final Outlet outlet;

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  Future<void> _toggle(BuildContext context, WidgetRef ref, Outlet o) async {
    final error = await ref.read(sellerOutletsProvider.notifier).toggle(o);
    if (error != null && context.mounted) AppToast.error(context, error);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Outlet o) async {
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
    if (ok != true || !context.mounted) return;

    final error = await ref.read(sellerOutletsProvider.notifier).delete(o);
    if (!context.mounted) return;
    AppToast.result(
      context,
      error: error,
      success: '"${o.name}" deleted successfully',
    );
    if (error == null) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the live copy so the switch and edits show up here at once.
    Outlet live = outlet;
    final list = ref.watch(sellerOutletsProvider).value;
    if (list != null) {
      for (final o in list) {
        if (o.id == outlet.id) live = o;
      }
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final created = live.createdAt == null
        ? null
        : _dateFmt.format(live.createdAt!.toLocal());

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Outlet details')),
        bottomNavigationBar: SellerBottomBar(
          label: 'Edit outlet',
          saving: false,
          onPressed: () => context.push('/seller/outlets/edit', extra: live),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SellerReveal(
              index: 0,
              child: Column(
                children: [
                  const SellerDetailAvatar(
                    url: null,
                    icon: Iconsax.location,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    live.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      SellerStatusPill(
                        text: live.isActive ? 'Active' : 'Inactive',
                        positive: live.isActive,
                      ),
                      if (live.isMain)
                        const SellerStatusPill(text: 'Main', positive: true),
                    ],
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
                    SellerInfoRow(label: 'Address', value: live.address),
                    SellerInfoRow(
                      label: 'Contact person',
                      value: live.contactPerson,
                    ),
                    SellerInfoRow(
                      label: 'Contact phone',
                      value: live.contactPhone,
                    ),
                    SellerInfoRow(label: 'Created', value: created),
                    SellerInfoRow(
                      label: 'Main outlet',
                      value: live.isMain ? 'Yes' : 'No',
                      last: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SellerReveal(
              index: 2,
              child: SellerSectionCard(
                icon: Iconsax.eye,
                title: 'Status',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Outlet is active',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  trailing: SellerToggle(
                    value: live.isActive,
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
              label: const Text('Delete outlet'),
            ),
          ],
        ),
      ),
    );
  }
}