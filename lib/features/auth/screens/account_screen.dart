// Place at: lib/features/account/screens/account_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/features/auth/screens/order_screen.dart';
import 'package:yanzee_app/features/auth/screens/widgets/login_prompt_sheet.dart';
import 'package:yanzee_app/features/auth/screens/login_screen.dart';
import 'package:yanzee_app/features/auth/screens/signup_screen.dart';

class AccountScreen extends StatefulWidget {
  static const routeName = '/account';

  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const _orderStages = [
    ('To Pay', Icons.receipt_long_outlined),
    ('To Ship', Icons.inventory_2_outlined),
    ('To Receive', Icons.local_shipping_outlined),
    ('To Review', Icons.rate_review_outlined),
    ('Returns', Icons.assignment_return_outlined),
  ];

  @override
  void initState() {
    super.initState();
    AuthState.instance.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthState.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => setState(() {});

  Future<void> _openOrders({int initialTab = 0}) async {
    final ok = await requireLogin(context);
    if (!ok || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrdersScreen(initialTabIndex: initialTab),
      ),
    );
  }

  Future<void> _openGatedSection(String label) async {
    final ok = await requireLogin(context);
    if (!ok || !mounted) return;
    // TODO: navigate to the real screen for `label` (Wishlist, Addresses, ...).
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Open $label')));
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthState.instance.isLoggedIn;
    final user = AuthState.instance.user;

    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(isLoggedIn, user),
            const SizedBox(height: 16),
            _buildOrdersCard(),
            const SizedBox(height: 16),
            _buildQuickLinks(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLoggedIn, UserProfile? user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn
                      ? 'Hello, ${user!.name}!'
                      : 'Hello, Welcome to YanZee!',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AuthColors.textDark,
                  ),
                ),
                if (isLoggedIn) ...[
                  const SizedBox(height: 4),
                  Text(
                    user!.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isLoggedIn) ...[
            OutlinedButton(
              // Direct navigation to the real login screen — NOT requireLogin(),
              // which is reserved for gating actions like Orders/Wishlist.
              onPressed: () => context.push(LoginScreen.routeName),
              style: OutlinedButton.styleFrom(
                foregroundColor: AuthColors.textDark,
                side: const BorderSide(color: AuthColors.borderDefault),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Login'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              // Direct navigation to the real signup screen — same reasoning.
              onPressed: () => context.push(SignupScreen.routeName),
              style: ElevatedButton.styleFrom(
                backgroundColor: AuthColors.submitButton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Sign Up'),
            ),
          ] else
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: AuthColors.iconMuted,
              ),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AuthColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () => _openOrders(),
                child: const Text(
                  'View All Orders',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_orderStages.length, (i) {
              final (label, icon) = _orderStages[i];
              return InkWell(
                onTap: () => _openOrders(initialTab: i),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Column(
                    children: [
                      Icon(icon, color: AuthColors.textDark),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AuthColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks() {
    const links = ['Orders', 'Wishlist', 'Addresses', 'Payment methods'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (final link in links)
            ListTile(
              title: Text(
                link,
                style: const TextStyle(
                  fontSize: 14,
                  color: AuthColors.textDark,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AuthColors.iconMuted,
              ),
              onTap: () =>
                  link == 'Orders' ? _openOrders() : _openGatedSection(link),
            ),
        ],
      ),
    );
  }
}
