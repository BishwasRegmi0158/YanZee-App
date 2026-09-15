import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
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

  List<Widget> _buildScreens() => const [
        HomeScreen(),
        ShopScreen(),
        WishlistScreen(),
        CartScreen(),
        AccountScreen(),
      ];

  List<PersistentBottomNavBarItem> _navBarItems() {
    final cartIconKey = ref.watch(cartIconKeyProvider);
    final wishlistIconKey = ref.watch(wishlistIconKeyProvider);
    final cartCount =
        ref.watch(cartProvider).values.fold<int>(0, (a, b) => a + b);
    final wishlistCount = ref.watch(wishlistProvider).length;

    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_outlined),
        title: 'Home',
        activeColorPrimary: Colors.black,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.storefront_outlined),
        title: 'Shop',
        activeColorPrimary: Colors.black,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: Badge(
          key: wishlistIconKey,
          label: Text('$wishlistCount'),
          isLabelVisible: wishlistCount > 0,
          child: const Icon(Icons.favorite_border),
        ),
        title: 'Wishlist',
        activeColorPrimary: Colors.black,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: Badge(
          key: cartIconKey,
          label: Text('$cartCount'),
          isLabelVisible: cartCount > 0,
          child: const Icon(Icons.shopping_bag_outlined),
        ),
        title: 'Cart',
        activeColorPrimary: Colors.black,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_outline),
        title: 'My Profile',
        activeColorPrimary: Colors.black,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarItems(),
      navBarStyle: NavBarStyle.style6,
      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
    );
  }
}