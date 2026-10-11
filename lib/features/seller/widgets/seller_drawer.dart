import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_store_provider.dart';

/// Lets any seller screen open the drawer owned by SellerShell.
final GlobalKey<ScaffoldState> sellerShellScaffoldKey =
    GlobalKey<ScaffoldState>();

/// Put this in a seller screen's AppBar: `leading: const SellerMenuButton()`.
class SellerMenuButton extends StatelessWidget {
  const SellerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Iconsax.menu_1, color: Colors.black),
      onPressed: () => sellerShellScaffoldKey.currentState?.openDrawer(),
    );
  }
}

class SellerDrawer extends ConsumerWidget {
  const SellerDrawer({super.key});

  static const _panel = Color(0xFFD5DBD3);
  static const _accent = Color(0xFF2E9E2E);
  static const _text = Color(0xFF3F473F);

  /// OWNER -> Owner, ORDER_MANAGER -> Order Manager
  String _roleLabel(String? role) {
    if (role == null || role.isEmpty) return '';
    return role
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  ImageProvider? _logo(WidgetRef ref) {
    final store = ref.watch(sellerStoreProvider);
    if (store.logoImage != null) {
      return ResizeImage(FileImage(store.logoImage!), width: 150, height: 150);
    }
    final url = store.logoUrl;
    if (url != null && url.isNotEmpty) {
      return ResizeImage(NetworkImage(url), width: 150, height: 150);
    }
    return null;
  }

  /// Closes the drawer, then runs [action] with the shell's (still mounted) context.
  void _run(BuildContext drawerContext, void Function(BuildContext) action) {
    final shellContext = sellerShellScaffoldKey.currentContext;
    Navigator.of(drawerContext).pop();
    if (shellContext != null && shellContext.mounted) action(shellContext);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(sellerStoreProvider);
    final shops = ref.watch(myShopsProvider).value ?? const <SellerShop>[];
    final currentId = ref.watch(myShopProvider).value?.id;
    final user = AuthState.instance.user;
    final logo = _logo(ref);
    final role = _roleLabel(user?.role);
    final subtitle = [
      if (user != null && user.name.isNotEmpty) user.name,
      if (role.isNotEmpty) role,
    ].join(' · ');

  

   return Drawer(
  backgroundColor: Colors.transparent,
  elevation: 0,
  width: 300,
  child: SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- store profile ----
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    backgroundImage: logo,
                    child: logo == null
                        ? const Icon(Iconsax.shop, color: _text)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name.isEmpty ? 'Your store' : store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _text.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ---- menu ----
              _item(
                Iconsax.category,
                'Categories',
                () => _run(
                  context,
                  (c) => GoRouter.of(c).push('/seller/categories'),
                ),
              ),
              _item(
                Iconsax.tag,
                'Brands',
                () => _run(
                  context,
                  (c) => GoRouter.of(c).push('/seller/brands'),
                ),
              ),
              _item(
                Iconsax.shop,
                'My shops',
                () => _run(
                  context,
                  (c) => GoRouter.of(c).push('/seller/shops'),
                ),
              ),
                            _item(
                Iconsax.add,
                'Add product',
                () => _run(
                  context,
                  (c) => GoRouter.of(c).push('/seller/products/add'),
                ),
              ),
              _item(
                Iconsax.eye,
                'Preview as customer',
                () => _run(
                  context,
                  (c) => GoRouter.of(c).push('/seller-profile'),
                ),
              ),

              // ---- shop switcher (only with 2+ shops) ----
              if (shops.length > 1) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 6),
                  child: Text(
                    'YOUR SHOPS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: _text.withOpacity(0.6),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      for (final s in shops)
                        _item(
                          s.id == currentId
                              ? Iconsax.tick_circle
                              : Iconsax.shop,
                          s.name,
                          () {
                            ref.read(selectedShopIdProvider.notifier).state =
                                s.id;
                            Navigator.of(context).pop();
                          },
                          highlighted: s.id == currentId,
                        ),
                    ],
                  ),
                ),
              ],

              const Spacer(),
              Divider(color: _text.withOpacity(0.15), height: 1),
              const SizedBox(height: 6),
              _item(
                Iconsax.logout,
                'Log out',
                () => _run(context, (c) async {
                  await AuthService.logout();
                  if (c.mounted) GoRouter.of(c).go('/home');
                }),
                color: const Color(0xFFE05A47),
              ),
            ],
          ),
        ),
      ),
  )
    );
  }

  Widget _item(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool highlighted = false,
    Color? color,
  }) {
    final tint = color ?? (highlighted ? _accent : _text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: highlighted
            ? Colors.white.withOpacity(0.55)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: tint),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: tint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}