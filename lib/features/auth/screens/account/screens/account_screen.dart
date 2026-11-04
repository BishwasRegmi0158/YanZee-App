import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/navigation/full_screen_nav.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/core/widgets/image_action_sheet.dart';
import 'package:yanzee_app/core/widgets/image_preview_screen.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/data/services/user_api_service.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/my_cards_screen.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/my_orders_screen.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/my_profile_screen.dart';
import 'package:yanzee_app/features/auth/screens/account/screens/settings_screen.dart';
import 'package:yanzee_app/features/auth/screens/login_screen.dart';
import 'package:yanzee_app/features/auth/screens/signup_screen.dart';
import 'package:yanzee_app/features/auth/screens/order_screen.dart';
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
    ('To Pay', Iconsax.receipt_1),
    ('To Ship', Iconsax.box),
    ('To Receive', Iconsax.truck),
    ('To Review', Iconsax.edit),
    ('Returns', Iconsax.receipt_item),
  ];

  final ImagePicker _imagePicker = ImagePicker();
  bool _isUpdatingPhoto = false;

  // Goes up after every successful photo change so the avatar reloads
  // even when the server keeps the same image URL.
  int _photoVersion = 0;

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

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  void _openOrderStages({int initialTab = 0}) {
    pushFullScreen(context, OrdersScreen(initialTabIndex: initialTab));
  }

  void _openScreen(Widget screen) {
    pushFullScreen(context, screen);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    ref.read(cartProvider.notifier).clear();
    ref.read(wishlistProvider.notifier).clear();
  }

  Future<void> _pickProfileImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUpdatingPhoto = true);
    String? error;
    try {
      // POST /images/user, then the logged-in user gets the new photo URL.
      await changeProfileImage(File(picked.path));
    } catch (e) {
      error = e is AuthException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;

    if (error == null) {
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
    }
    setState(() {
      _isUpdatingPhoto = false;
      if (error == null) _photoVersion++;
    });

    AppToast.result(
      context,
      error: error,
      success: 'Profile photo updated',
    );
  }

  Future<void> _deleteProfileImage() async {
    AppToast.info(
      context,
      'Removing the photo is not available yet. Choose a new photo to replace it.',
    );
  }

  void _showAvatarOptions(bool hasImage, String? imagePath) {
    showImageActionSheet(
      context: context,
      hasImage: hasImage,
      onPreview: () {
        if (imagePath == null) return;
        pushFullScreen(
          context,
          ImagePreviewScreen(
            imagePath: imagePath,
            onDelete: _deleteProfileImage,
          ),
        );
      },
      onChange: _pickProfileImage,
      onDelete: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthState.instance.isLoggedIn;
    final user = AuthState.instance.user;

    // Inter is applied to this screen only. The app-wide theme is untouched.
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
      ),
      child: Scaffold(
        backgroundColor: AuthColors.pageBackground,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(isLoggedIn, user),
              const SizedBox(height: 16),
              _buildOrdersCard(),
              const SizedBox(height: 16),
              _buildQuickLinks(isLoggedIn),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLoggedIn, UserProfile? user) {
    return Container(
      width: double.infinity,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AuthColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello, Welcome to YanZee!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AuthColors.textDark,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(LoginScreen.routeName),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AuthColors.textDark,
                          side: const BorderSide(
                            color: AuthColors.borderDefault,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
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
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildAvatar(UserProfile? user) {
    final image = user?.image;
    final hasImage = image != null && image.isNotEmpty;

    ImageProvider? provider;
    if (hasImage) {
      final ImageProvider source = image.startsWith('http')
          ? NetworkImage(image)
          : FileImage(File(image));
      provider = ResizeImage(source, width: 300, height: 300);
    }

    return InkWell(
      onTap: _isUpdatingPhoto ? null : () => _showAvatarOptions(hasImage, image),
      customBorder: const CircleBorder(),
      child: Stack(
        children: [
          CircleAvatar(
            key: ValueKey(_photoVersion),
            radius: 50,
            backgroundColor: const Color(0xFFF0EEEA),
            backgroundImage: provider,
            child: _isUpdatingPhoto
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (!hasImage
                    ? const Icon(
                        Iconsax.profile_circle,
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
                Iconsax.camera,
                size: 14,
                color: Colors.white,
              ),
            ),
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
            children: List.generate(_orderStages.length, (i) {
              final (label, icon) = _orderStages[i];
              return Expanded(
                child: InkWell(
                  onTap: () => _openOrderStages(initialTab: i),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 2,
                    ),
                    child: Column(
                      children: [
                        Icon(icon, color: AuthColors.textDark),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AuthColors.textDark,
                          ),
                        ),
                      ],
                    ),
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
          if (isLoggedIn) ...[
            _linkTile(
              Iconsax.user,
              'My Profile',
              () => _openScreen(const MyProfileScreen()),
            ),
            _divider(),
          ],
          _linkTile(
            Iconsax.truck,
            'My Orders',
            () => _openScreen(const MyOrdersScreen()),
          ),
          _divider(),
          _linkTile(
            Iconsax.card,
            'My Cards',
            () => _openScreen(const MyCardsScreen()),
          ),
          _divider(),
          _linkTile(
            Iconsax.setting_2,
            'Settings',
            () => _openScreen(const SettingsScreen()),
          ),
          if (isLoggedIn) ...[
            _divider(),
            _linkTile(
              Iconsax.logout,
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
      trailing: const Icon(Iconsax.arrow_right_3, color: AuthColors.iconMuted),
      onTap: onTap,
    );
  }
}