import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/feed/feed_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/profile/addresses_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/catalog/catalog_screen.dart';
import 'features/feed/product.dart';
import 'features/feed/product_details_screen.dart';
import 'shared/app_shell.dart';

class DopamineShopApp extends StatelessWidget {
  const DopamineShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Dopamine Shop',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
        GoRoute(
          path: '/catalog',
          builder: (context, state) => const CatalogScreen(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Избранное'))),
        ),
        GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/addresses',
          builder: (context, state) => const AddressesScreen(),
        ),
        GoRoute(
          path: '/product-details',
          builder: (context, state) =>
              ProductDetailsScreen(product: state.extra as Product),
        ),
      ],
    ),
  ],
);
