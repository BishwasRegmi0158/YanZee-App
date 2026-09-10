import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/my_address_screen.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/my_cards_screen.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/my_orders_screen.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/my_profile_screen.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/settings_screen.dart';
import 'package:yanzee_app/features/auth/screens/login_screen.dart';
import 'package:yanzee_app/features/auth/screens/signup_screen.dart';
import 'package:yanzee_app/features/auth/screens/order_screen.dart';
import 'package:yanzee_app/features/auth/screens/widgets/login_prompt_sheet.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
import 'package:yanzee_app/features/wishlist/provider/wishlist_provider.dart';


class AccountScreen extends ConsumerStatefulWidget {
  static const routeName = '/account';

  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  static const _orderStages = [
    ('To Pay', Icons.receipt_long_outlined),
    ('To Ship', Icons.inventory_2_outlined),
    ('To Receive', Icons.local_shipping_outlined),
    ('To Review', Icons.rate_review_outlined),
    ('Returns', Icons.assignment_return_outlined),
  ];

  final ImagePicker _imagePicker = ImagePicker();
  bool _isUpdatingPhoto = false;

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

  Future<void> _openOrderStages({int initialTab = 0}) async {
    final ok = await requireLogin(context);
    if (!ok || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrdersScreen(initialTabIndex: initialTab),
      ),
    );
  }

  Future<void> _openScreen(Widget screen) async {
    final ok = await requireLogin(context);
    if (!ok || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Logs the account out AND clears cart/wishlist state, so the next
  /// person to log in on this device doesn't inherit someone else's items.
  void _logout() {
    AuthState.instance.logout();
    ref.read(cartProvider.notifier).clear();
    ref.read(wishlistProvider.notifier).clear();
  }

  /// Profile photo always starts blank (no default placeholder image) —
  /// the person picks one from their gallery whenever they want.
  Future<void> _pickProfileImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUpdatingPhoto = true);
    final user = AuthState.instance.user;
    try {
      await AuthService.updateProfile(
        name: user?.name ?? '',
        email: user?.email ?? '',
        phone: user?.phone ?? '',
        image: picked.path,
      );
    } catch (_) {
      // Non-fatal — the person can retry by tapping the avatar again.
    }
    if (!mounted) return;
    setState(() => _isUpdatingPhoto = false);
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
            if (isLoggedIn) ...[
              const SizedBox(height: 16),
              _buildPrimaryAddressCard(),
            ],
            const SizedBox(height: 16),
            _buildOrdersCard(),
            const SizedBox(height: 16),
            _buildQuickLinks(isLoggedIn),
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
      child: isLoggedIn
          ? Column(
              children: [
                _buildAvatar(user),
                const SizedBox(height: 12),
                Text(
                  user!.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AuthColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Expanded(
                  child: Text(
                    'Hello, Welcome to YanZee!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AuthColors.textDark,
                    ),
                  ),
                ),
                OutlinedButton(
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
              ],
            ),
    );
  }

  Widget _buildAvatar(UserProfile? user) {
    final image = user?.image;
    final hasImage = image != null && image.isNotEmpty;

    return InkWell(
      onTap: _isUpdatingPhoto ? null : _pickProfileImage,
      customBorder: const CircleBorder(),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFF0EEEA),
            backgroundImage: hasImage
                ? (image.startsWith('http')
                      ? NetworkImage(image)
                      : FileImage(File(image)) as ImageProvider)
                : null,
            child: _isUpdatingPhoto
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (!hasImage
                      ? const Icon(
                          Icons.person,
                          size: 46,
                          color: AuthColors.iconMuted,
                        )
                      : null),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAddressCard() {
    final address = AuthState.instance.defaultAddress;
    if (address == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Row(
                children: [
                  Icon(Icons.place_outlined, size: 18, color: AuthColors.textDark),
                  SizedBox(width: 8),
                  Text(
                    'Primary Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AuthColors.textDark,
                    ),
                  ),
                ],
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEBE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PRIMARY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address.fullName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone, size: 13, color: Color(0xFF9A9A9A)),
              const SizedBox(width: 6),
              Text(
                address.phone,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address.summary,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B), height: 1.4),
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
                onPressed: () => _openScreen(const MyOrdersScreen()),
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
                onTap: () => _openOrderStages(initialTab: i),
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

  Widget _buildQuickLinks(bool isLoggedIn) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _linkTile(
            Icons.person_outline,
            'My Profile',
            () => _openScreen(const MyProfileScreen()),
          ),
          _divider(),
          _linkTile(
            Icons.place_outlined,
            'My Address',
            () => _openScreen(const MyAddressScreen()),
          ),
          _divider(),
          _linkTile(
            Icons.local_shipping_outlined,
            'My Orders',
            () => _openScreen(const MyOrdersScreen()),
          ),
          _divider(),
          _linkTile(
            Icons.credit_card_outlined,
            'My Cards',
            () => _openScreen(const MyCardsScreen()),
          ),
          _divider(),
          _linkTile(
            Icons.settings_outlined,
            'Settings',
            () => _openScreen(const SettingsScreen()),
          ),
          if (isLoggedIn) ...[
            _divider(),
            _linkTile(
              Icons.logout,
              'Log Out',
              _logout,
              color: const Color(0xFFE05A47),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    height: 1,
    color: Color(0xFFEDEBE7),
    indent: 16,
    endIndent: 16,
  );

  Widget _linkTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final tint = color ?? AuthColors.textDark;
    return ListTile(
      leading: Icon(icon, color: tint, size: 21),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: tint,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AuthColors.iconMuted),
      onTap: onTap,
    );
  }
}