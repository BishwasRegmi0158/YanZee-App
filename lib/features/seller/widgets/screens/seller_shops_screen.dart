import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';
import 'package:yanzee_app/data/services/shop_publish_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/seller_toggle.dart';

String? _s(Object? v) => v?.toString();

class SellerShopsScreen extends ConsumerStatefulWidget {
  const SellerShopsScreen({super.key});

  @override
  ConsumerState<SellerShopsScreen> createState() => _SellerShopsScreenState();
}

class _SellerShopsScreenState extends ConsumerState<SellerShopsScreen> {
  String _query = '';
  final Set<String> _busy = {};

  Future<void> _togglePublish(SellerShop shop) async {
    if (_busy.contains(shop.id)) return;
    setState(() => _busy.add(shop.id));
    try {
      final result = await ref
          .read(shopPublishApiServiceProvider)
          .togglePublish(shop.id);
      try {
        // ignore: unused_result
        await ref.refresh(myShopsProvider.future);
      } catch (_) {
        // The change worked; the list will update on the next refresh.
      }
      if (!mounted) return;
      AppToast.success(context, result.message);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(shop.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(myShopsProvider);
    final currentId = ref.watch(myShopProvider).value?.id;

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('My shops')),
        bottomNavigationBar: SellerBottomBar(
          label: 'Create shop',
          saving: false,
          onPressed: () => context.push('/seller/create-shop'),
        ),
        body: shopsAsync.when(
          skipLoadingOnReload: true,
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
                    onPressed: () => ref.invalidate(myShopsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (shops) {
            final q = _query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? shops
                : shops.where((s) => s.name.toLowerCase().contains(q)).toList();

            return RefreshIndicator(
              onRefresh: () => ref.refresh(myShopsProvider.future),
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
                      hintText: 'Search shops',
                      prefixIcon: Icon(Iconsax.search_normal_1, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${shops.length} shop${shops.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          shops.isEmpty
                              ? 'No shops yet.'
                              : 'No shops match "$_query"',
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < filtered.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SellerReveal(
                          index: i < 6 ? i : 6,
                          child: _ShopCard(
                            shop: filtered[i],
                            isCurrent: filtered[i].id == currentId,
                            busy: _busy.contains(filtered[i].id),
                            onTap: () => context.push(
                              '/seller/shops/detail',
                              extra: filtered[i].id,
                            ),
                            onToggle: () => _togglePublish(filtered[i]),
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

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.isCurrent,
    required this.busy,
    required this.onTap,
    required this.onToggle,
  });

  final SellerShop shop;
  final bool isCurrent;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final published = shop.isPublished == true;

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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SellerDetailAvatar(
                url: _s(shop.logo),
                icon: Iconsax.shop,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      storeCategoryLabel(_s(shop.category) ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        SellerStatusPill(
                          text: published ? 'Published' : 'Unpublished',
                          positive: published,
                        ),
                        if (isCurrent)
                          const SellerStatusPill(
                            text: 'Managing now',
                            positive: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 8),
              SellerToggle(
                value: busy ? !published : published,
                loading: busy,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}