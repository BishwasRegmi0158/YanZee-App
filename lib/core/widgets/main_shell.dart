import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:yanzee_app/core/provider/main_tab_provider.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/account_screen.dart';
import 'package:yanzee_app/features/cart/provider/cart_icon_key_provider.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
import 'package:yanzee_app/features/cart/screens/cart_screen.dart';
import 'package:yanzee_app/features/home/screens/home_screen.dart';
import 'package:yanzee_app/features/shop/screens/shop_screen.dart';
import 'package:yanzee_app/features/wishlist/provider/wishlist_icon_key_provider.dart';
import 'package:yanzee_app/features/wishlist/provider/wishlist_provider.dart';
import 'package:yanzee_app/features/wishlist/screens/wishlist_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  List<CustomNavBarScreen> _buildScreens() => const [
        CustomNavBarScreen(screen: HomeScreen()),
        CustomNavBarScreen(screen: ShopScreen()),
        CustomNavBarScreen(screen: WishlistScreen()),
        CustomNavBarScreen(screen: CartScreen()),
        CustomNavBarScreen(screen: AccountScreen()),
      ];

  void _selectTab(int index) {
    setState(() => _controller.index = index);
    ref.read(mainTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final cartIconKey = ref.watch(cartIconKeyProvider);
    final wishlistIconKey = ref.watch(wishlistIconKeyProvider);
    final cartCount =
        ref.watch(cartProvider).values.fold<int>(0, (a, b) => a + b);
    final wishlistCount = ref.watch(wishlistProvider).length;


    ref.listen<int>(mainTabIndexProvider, (previous, next) {
      if (next != _controller.index) {
        setState(() => _controller.index = next);
      }
    });

    return PersistentTabView.custom(
      context,
      controller: _controller,
      itemCount: 5,
      screens: _buildScreens(),
      customWidget: _MainNavBar(
        selectedIndex: _controller.index,
        cartCount: cartCount,
        wishlistCount: wishlistCount,
        cartIconKey: cartIconKey,
        wishlistIconKey: wishlistIconKey,
        onItemSelected: _selectTab,
      ),
      navBarHeight: 64,
      backgroundColor: Colors.white,
      confineToSafeArea: true,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
}

class _MainNavBar extends StatelessWidget {
  const _MainNavBar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.cartCount,
    required this.wishlistCount,
    required this.cartIconKey,
    required this.wishlistIconKey,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final int cartCount;
  final int wishlistCount;
  final Key cartIconKey;
  final Key wishlistIconKey;

  static const List<_NavItem> _items = [
    _NavItem(activeIcon: Iconsax.home_15, inactiveIcon: Iconsax.home_1, label: 'Home'),
    _NavItem(activeIcon: Iconsax.shop5, inactiveIcon: Iconsax.shop, label: 'Shop'),
    _NavItem(activeIcon: Iconsax.heart5, inactiveIcon: Iconsax.heart, label: 'Wishlist'),
    _NavItem(activeIcon: Iconsax.shopping_cart5, inactiveIcon: Iconsax.shopping_cart, label: 'Cart'),
    _NavItem(activeIcon: Iconsax.profile_circle5, inactiveIcon: Iconsax.profile_circle, label: 'Profile'),
  ];

  static const double _iconLabelGap = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isSelected = index == selectedIndex;

            Widget icon = Icon(
              isSelected ? item.activeIcon : item.inactiveIcon,
              size: 22,
              color: isSelected ? Colors.black : Colors.grey,
            );

            if (index == 2) {
              icon = Badge(
                key: wishlistIconKey,
                label: Text('$wishlistCount'),
                isLabelVisible: wishlistCount > 0,
                child: icon,
              );
            } else if (index == 3) {
              icon = Badge(
                key: cartIconKey,
                label: Text('$cartCount'),
                isLabelVisible: cartCount > 0,
                child: icon,
              );
            }

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onItemSelected(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(height: _iconLabelGap),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? Colors.black : Colors.grey,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}