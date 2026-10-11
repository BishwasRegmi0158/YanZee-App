import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/core/widgets/main_shell.dart';
import 'package:yanzee_app/data/models/brand.dart';
import 'package:yanzee_app/data/models/product.dart';
import 'package:yanzee_app/data/models/shop_category.dart';
import 'package:yanzee_app/features/auth/screens/login_screen.dart';
import 'package:yanzee_app/features/auth/screens/signup_screen.dart';
import 'package:yanzee_app/features/checkout/screens/checkout_screen.dart';
import 'package:yanzee_app/features/home/screens/category_products_screen.dart';
import 'package:yanzee_app/features/home/screens/new_arrivals_screen.dart';
import 'package:yanzee_app/features/home/screens/product_detail_screen.dart';
import 'package:yanzee_app/features/home/screens/search_screen.dart';

import 'package:yanzee_app/features/home/screens/widgets/categories_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/brand_detail_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/brand_form_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/brands_screen.dart';

import 'package:yanzee_app/features/seller/widgets/screens/categories_screen.dart'
    as seller_categories;
import 'package:yanzee_app/features/seller/widgets/screens/category_detail_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/category_form_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/create_category_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/create_shop_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/product_form_screen.dart';
import 'package:yanzee_app/features/seller/widgets/screens/seller_shops_screen.dart';
import 'package:yanzee_app/features/seller/widgets/seller_gate.dart';
import 'package:yanzee_app/features/shop/screens/seller_profile_screen.dart';
import 'package:yanzee_app/features/shop/screens/shop_detail_screen.dart' as seller_shop;
import 'package:yanzee_app/features/splash/screens/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final auth = AuthState.instance;
    final loc = state.matchedLocation;

    final goingToAuth =
        loc == LoginScreen.routeName || loc == SignupScreen.routeName;

    // Logged-in users don't need the login/signup pages.
    if (auth.isLoggedIn && goingToAuth) return auth.homeRoute;

    // Shop owners live in the seller dashboard, not the customer shell.
    if (auth.isShopOwner && loc.startsWith('/home')) {
      return '/seller-dashboard';
    }

    // Only shop owners may open the seller dashboard.
    if (loc == '/seller-dashboard' && !auth.isShopOwner) return '/home';

    // Only shop owners may open the seller pages (brands, categories...).
    if (loc.startsWith('/seller/') && !auth.isShopOwner) return '/home';

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
      builder: (context, state) => const SellerGate(),
    ),

    // ---- seller pages opened from the side menu ----
    GoRoute(
      path: '/seller/create-category',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateCategoryScreen(),
    ),
    GoRoute(
      path: '/seller/create-shop',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateShopScreen(isAdditional: true),
    ),
    GoRoute(
      path: '/seller/brands',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BrandsScreen(),
    ),
    GoRoute(
      path: '/seller/brands/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BrandFormScreen(),
    ),
    GoRoute(
      path: '/seller/brands/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final brand = state.extra as Brand?;
        if (brand == null) {
          return const Scaffold(body: Center(child: Text('Brand not found')));
        }
        return BrandFormScreen(initial: brand);
      },
    ),
    GoRoute(
      path: '/seller/brands/detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final brand = state.extra as Brand?;
        if (brand == null) {
          return const Scaffold(body: Center(child: Text('Brand not found')));
        }
        return BrandDetailScreen(brand: brand);
      },
    ),
    GoRoute(
      path: '/seller/shops',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SellerShopsScreen(),
    ),
    GoRoute(
      path: '/seller/shops/detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.extra as String?;
        if (id == null) {
          return const Scaffold(body: Center(child: Text('Shop not found')));
        }
        return seller_shop.ShopDetailScreen(shopId: id);
      },
    ),
    GoRoute(
      path: '/seller/categories',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const seller_categories.CategoriesScreen(),
    ),
    GoRoute(
      path: '/seller/categories/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CategoryFormScreen(),
    ),
    GoRoute(
      path: '/seller/categories/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final c = state.extra as ShopCategory?;
        if (c == null) {
          return const Scaffold(
            body: Center(child: Text('Category not found')),
          );
        }
        return CategoryFormScreen(initial: c);
      },

    ),
        GoRoute(
      path: '/seller/products/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProductFormScreen(),
    ),
    GoRoute(
      path: '/seller/categories/detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final c = state.extra as ShopCategory?;
        if (c == null) {
          return const Scaffold(
            body: Center(child: Text('Category not found')),
          );
        }
        return CategoryDetailScreen(category: c);
      },
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