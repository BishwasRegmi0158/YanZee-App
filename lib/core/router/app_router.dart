import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/core/widgets/main_shell.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/auth/screens/account_screen.dart';
import 'package:yanzee_app/features/auth/screens/login_screen.dart';
import 'package:yanzee_app/features/auth/screens/signup_screen.dart';
import 'package:yanzee_app/features/cart/screens/cart_screen.dart';
import 'package:yanzee_app/features/home/screens/category_products_screen.dart';
import 'package:yanzee_app/features/home/screens/home_screen.dart';
import 'package:yanzee_app/features/home/screens/new_arrivals_screen.dart';
import 'package:yanzee_app/features/home/screens/product_detail_screen.dart';
import 'package:yanzee_app/features/home/screens/search_screen.dart';
import 'package:yanzee_app/features/home/screens/widgets/categories_screen.dart';
import 'package:yanzee_app/features/shop/screens/shop_screen.dart';
import 'package:yanzee_app/features/splash/screens/splash_screen.dart';
import 'package:yanzee_app/features/wishlist/screens/wishlist_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
 
  refreshListenable: AuthState.instance,
  redirect: (context, state) {
    final loggedIn = AuthState.instance.isLoggedIn;
    final goingToAuth = state.matchedLocation == LoginScreen.routeName ||
        state.matchedLocation == SignupScreen.routeName;

  
    if (loggedIn && goingToAuth) {
      return '/my-profile';
    }

    return null; // no redirect needed
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'category/:slug',
                  builder: (context, state) {
                    final slug = state.pathParameters['slug']!;
                    final displayName = state.extra as String? ?? slug;
                    return CategoryProductsScreen(
                      categorySlug: slug,
                      displayName: displayName,
                    );
                  },
                ),
                GoRoute(
                  path: 'new-arrivals',
                  builder: (context, state) => const NewArrivalsScreen(),
                ),
                GoRoute(
                  path: 'categories',
                  builder: (context, state) => const CategoriesScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shop',
              builder: (context, state) => const ShopScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wishlist',
              builder: (context, state) => const WishlistScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              // Path stays URL-safe (no space/capital); the bottom-nav
              // label shown to the user ("My Profile") lives in MainShell
              // and is unaffected by this.
              path: '/my-profile',
              builder: (context, state) => const AccountScreen(),
            ),
          ],
        ),
        // duplicate '/shop' branch removed — was causing a 6th branch
        // against a 5-tab bottom nav
      ],
    ),
    GoRoute(
      path: '/product/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final product = state.extra as Product;
        return ProductDetailScreen(product: product);
      },
    ),
    GoRoute(
      path: LoginScreen.routeName,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: SignupScreen.routeName,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
  ],
);