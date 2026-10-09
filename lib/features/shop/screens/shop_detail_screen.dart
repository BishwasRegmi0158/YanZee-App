import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';
import 'package:yanzee_app/data/services/shop_publish_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/seller_detail_widgets.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_toggle.dart';

String? _s(Object? v) => v?.toString();

/// "ACTIVE" -> "Active"
String? _statusLabel(String? s) {
  if (s == null || s.isEmpty) return null;
  return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({super.key, required this.shopId});

  final String shopId;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  bool _busy = false;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _togglePublish(SellerShop shop) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(shopPublishApiServiceProvider)
          .togglePublish(shop.id);
      try {
        await ref.refresh(myShopsProvider.future);
      } catch (_) {
        // The change worked; the list will update on the next refresh.
      }
      if (!mounted) return;
      _snack(result.message);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _switchTo(SellerShop shop) {
    ref.read(selectedShopIdProvider.notifier).state = shop.id;
    _snack('Now managing ${shop.name}');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(myShopsProvider);
    final currentId = ref.watch(myShopProvider).value?.id;

    SellerShop? shop;
    final list = shopsAsync.value;
    if (list != null) {
      for (final s in list) {
        if (s.id == widget.shopId) shop = s;
      }
    }

    if (shop == null) {
      return SellerFormTheme(
        child: Scaffold(
          appBar: AppBar(title: const Text('Shop details')),
          body: Center(
            child: shopsAsync.isLoading
                ? const CircularProgressIndicator()
                : const Text('Shop not found'),
          ),
        ),
      );
    }

    final current = shop;
    final published = current.isPublished == true;
    final isCurrent = current.id == currentId;
    final theme = Theme.of(context);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Shop details')),
        bottomNavigationBar: isCurrent
            ? null
            : SellerBottomBar(
                label: 'Switch to this shop',
                saving: false,
                onPressed: () => _switchTo(current),
              ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SellerReveal(
              index: 0,
              child: Column(
                children: [
                  SellerDetailAvatar(
                    url: _s(current.logo),
                    icon: Iconsax.shop,
                    circular: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    current.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
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
            const SizedBox(height: 24),
            SellerReveal(
              index: 1,
              child: SellerSectionCard(
                icon: Iconsax.info_circle,
                title: 'Details',
                child: Column(
                  children: [
                    SellerInfoRow(label: 'Name', value: current.name),
                    SellerInfoRow(label: 'Slug', value: _s(current.slug)),
                    SellerInfoRow(
                      label: 'Category',
                      value: storeCategoryLabel(_s(current.category) ?? ''),
                    ),
                    SellerInfoRow(
                      label: 'Status',
                      value: _statusLabel(_s(current.status)),
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
                icon: Iconsax.call,
                title: 'Contact',
                child: Column(
                  children: [
                    SellerInfoRow(
                      label: 'Email',
                      value: _s(current.contactEmail),
                    ),
                    SellerInfoRow(
                      label: 'Phone',
                      value: _s(current.contactPhone),
                    ),
                    SellerInfoRow(
                      label: 'Address',
                      value: _s(current.storeAddress),
                      last: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SellerReveal(
              index: 3,
              child: SellerSectionCard(
                icon: Iconsax.eye,
                title: 'Visibility',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Published',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    published
                        ? 'Customers can see this shop.'
                        : 'Hidden from customers.',
                  ),
                  trailing: SellerToggle(
                    value: published,
                    onChanged: _busy ? null : (_) => _togglePublish(current),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
