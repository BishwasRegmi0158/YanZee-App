import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/core/widgets/main_shell.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/features/auth/screens/login_screen.dart';
import 'package:yanzee_app/features/auth/screens/signup_screen.dart';
import 'package:yanzee_app/features/checkout/screens/checkout_screen.dart';
import 'package:yanzee_app/features/home/screens/category_products_screen.dart';
import 'package:yanzee_app/features/home/screens/new_arrivals_screen.dart';
import 'package:yanzee_app/features/home/screens/product_detail_screen.dart';
import 'package:yanzee_app/features/home/screens/search_screen.dart';
import 'package:yanzee_app/features/home/screens/widgets/categories_screen.dart';
import 'package:yanzee_app/features/seller/widgets/seller_shell.dart';
import 'package:yanzee_app/features/shop/screens/seller_profile_screen.dart';
import 'package:yanzee_app/features/splash/screens/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = AuthState.instance.isLoggedIn;
    final goingToAuth =
        state.matchedLocation == LoginScreen.routeName ||
        state.matchedLocation == SignupScreen.routeName;

    if (loggedIn && goingToAuth) {
      return '/home';
    }

    return null; // no redirect needed
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

 
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainShell(),
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

    GoRoute(
      path: '/seller-dashboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SellerShell(),
    ),

    GoRoute(
      path: '/product/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final product = state.extra as Product?;
        if (product == null) {
          return const Scaffold(body: Center(child: Text('Product not found')));
        }
        return ProductDetailScreen(product: product);
      },
    ),
    GoRoute(
      path: '/seller-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SellerProfileScreen(),
    ),
    GoRoute(
      path: CheckoutScreen.routeName,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        final items = extra is Map<String, dynamic>
            ? extra['items'] as List<CheckoutItem>?
            : null;
        return CheckoutScreen(items: items ?? const []);
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