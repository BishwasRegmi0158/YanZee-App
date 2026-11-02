import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/navigation/full_screen_nav.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/core/widgets/image_action_sheet.dart';
import 'package:yanzee_app/core/widgets/image_preview_screen.dart';
import 'package:yanzee_app/core/widgets/keyboard_safe_sheet.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';
import 'package:yanzee_app/data/models/seller_store.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_products_provider.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_store_provider.dart';
import 'package:yanzee_app/features/seller/widgets/seller_drawer.dart';

class SellerStoreScreen extends ConsumerWidget {
  const SellerStoreScreen({super.key});

  /// Runs a save and shows the error (if any) as a pop-up.
  Future<void> _save(
    BuildContext context,
    Future<String?> Function() action,
  ) async {
    final error = await action();
    if (error != null && context.mounted) {
      AppToast.error(context, error);
    }
  }

  Future<void> _pickLogo(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && context.mounted) {
      final notifier = ref.read(sellerStoreProvider.notifier);
      _save(context, () => notifier.updateLogo(File(picked.path)));
    }
  }

  void _previewLogo(BuildContext context, WidgetRef ref, SellerStore store) {
    final notifier = ref.read(sellerStoreProvider.notifier);
    final file = store.logoImage;
    final url = store.logoUrl;

    if (file != null) {
      pushFullScreen(
        context,
        ImagePreviewScreen(
          imagePath: file.path,
          onDelete: () => _save(context, () => notifier.removeLogo()),
        ),
      );
    } else if (url != null) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.r2xl),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      );
    }
  }

  void _showLogoOptions(
    BuildContext context,
    WidgetRef ref,
    SellerStore store,
  ) {
    final hasImage = store.logoImage != null || store.logoUrl != null;

    showImageActionSheet(
      context: context,
      hasImage: hasImage,
      onPreview: () => _previewLogo(context, ref, store),
      onChange: () => _pickLogo(context, ref),
      // The backend has no "remove logo" API yet, so the option is hidden.
      onDelete: null,
    );
  }

  Future<void> _editField({
    required BuildContext context,
    required String label,
    required String currentValue,
    required void Function(String) onSave,
    int maxLines = 1,
  }) async {
    final result = await showKeyboardSafeSheet<String>(
      context: context,
      builder: (ctx) => _EditFieldForm(
        label: label,
        currentValue: currentValue,
        maxLines: maxLines,
      ),
    );

    if (context.mounted && result != null && result.isNotEmpty) {
      onSave(result);
    }
  }

  bool _isEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _pickCategory(
    BuildContext context,
    WidgetRef ref,
    SellerStore store,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Select category',
                style: ctx.text.headlineSmall,
              ),
            ),
            for (final c in kStoreCategories)
              ListTile(
                title: Text(storeCategoryLabel(c)),
                trailing: c == store.category
                    ? Icon(Icons.check, color: ctx.colors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(c),
              ),
          ],
        ),
      ),
    );

    if (picked == null || picked == store.category || !context.mounted) return;
    final notifier = ref.read(sellerStoreProvider.notifier);
    _save(context, () => notifier.updateField(category: picked));
  }

  // ignore: unused_element
  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to log in again to open your store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: ctx.colors.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    // POST /auth/logout, clears the saved refresh token and AuthState
    await AuthService.logout();
    if (!context.mounted) return;

    // The user is no longer a shop owner, so go to the customer home.
    context.go('/home');
  }

  Future<void> _confirmDeleteShop(
    BuildContext context,
    WidgetRef ref,
    String shopName,
  ) async {
    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null || storeId.isEmpty) {
      AppToast.error(context, 'No store loaded.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete store?'),
        content: Text(
          '"$shopName" will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: ctx.colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    // Block the screen with a spinner while the server works.
    final nav = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    String? error;
    try {
      // DELETE /stores with the x-store-id header
      await ref.read(shopApiServiceProvider).deleteStore(storeId);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    nav.pop(); // close the spinner

    if (!context.mounted) return;
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    AppToast.success(context, 'Store deleted successfully');
    // Reload the list of shops. If another shop is left, the gate falls back
    // to it; if none is left, the gate shows Create Store.
    ref.invalidate(sellerProductsProvider);
    ref.invalidate(myShopsProvider);
  }

  /// A freshly picked file wins (instant preview); otherwise the saved URL.
  ImageProvider? _getLogoProvider(SellerStore store) {
    if (store.logoImage != null) {
      return ResizeImage(FileImage(store.logoImage!), width: 300, height: 300);
    }
    if (store.logoUrl != null) {
      return ResizeImage(NetworkImage(store.logoUrl!), width: 300, height: 300);
    }
    return null;
  }

  /// "ACTIVE" + published -> "Active · Published".
  String _statusText(SellerStore store) {
    final status = store.status.isEmpty
        ? 'Unknown'
        : '${store.status[0]}${store.status.substring(1).toLowerCase()}';
    return '$status · ${store.isPublished ? 'Published' : 'Not published'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final store = ref.watch(sellerStoreProvider);
    final notifier = ref.read(sellerStoreProvider.notifier);
    final logoProvider = _getLogoProvider(store);

    return Scaffold(
      appBar: AppBar(
        leading: const SellerMenuButton(),
        title: const Text('Store'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: colors.surfaceContainerLowest,
                  backgroundImage: logoProvider,
                  child: logoProvider == null
                      ? Icon(
                          Iconsax.shop,
                          size: 36,
                          color: colors.onSurfaceVariant,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showLogoOptions(context, ref, store),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Iconsax.camera,
                        color: colors.onPrimary,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _tile(
            context,
            Iconsax.shop,
            'Store name',
            store.name,
            onEdit: (v) => _save(context, () => notifier.updateField(name: v)),
          ),
          _tile(
            context,
            Iconsax.category,
            'Category',
            storeCategoryLabel(store.category),
            onTap: () => _pickCategory(context, ref, store),
          ),
          // The backend never returns the email, so show a hint until the
          // owner sets one in this session.
          _tile(
            context,
            Iconsax.sms,
            'Contact email',
            store.contactEmail ?? 'Tap to update',
            muted: store.contactEmail == null,
            editStartsEmpty: store.contactEmail == null,
            onEdit: (v) {
              if (!_isEmail(v)) {
                AppToast.error(context, 'Enter a valid email.');
                return;
              }
              _save(context, () => notifier.updateField(contactEmail: v));
            },
          ),
          _tile(
            context,
            Iconsax.tick_circle,
            'Status',
            _statusText(store),
            readOnly: true,
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'DELETE',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          _deleteButton(context, ref, store.name),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Full-width outlined destructive button.
  Widget _deleteButton(BuildContext context, WidgetRef ref, String shopName) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _confirmDeleteShop(context, ref, shopName),
        icon: Icon(Iconsax.trash, size: 18, color: colors.error),
        label: Text(
          'Delete store',
          style: TextStyle(
            color: colors.error,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.error, width: 1.2),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _logoutButton(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: Icon(Iconsax.logout, size: 18, color: colors.error),
        label: Text(
          'Log out',
          style: TextStyle(color: colors.error, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(side: BorderSide(color: colors.error)),
      ),
    );
  }

  /// Tapping opens a text editor (onEdit) or a custom action (onTap).
  /// readOnly tiles show no arrow and do nothing when tapped.
  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    void Function(String)? onEdit,
    VoidCallback? onTap,
    int maxLines = 1,
    bool readOnly = false,
    bool muted = false,
    bool editStartsEmpty = false,
  }) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.r2xl),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: readOnly
              ? null
              : (onTap ??
                    () => _editField(
                      context: context,
                      label: label,
                      currentValue: editStartsEmpty ? '' : value,
                      onSave: onEdit!,
                      maxLines: maxLines,
                    )),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colors.onSurface),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: muted
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!readOnly)
                  Icon(
                    Iconsax.arrow_right_3,
                    color: colors.onSurfaceVariant,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditFieldForm extends StatefulWidget {
  final String label;
  final String currentValue;
  final int maxLines;

  const _EditFieldForm({
    required this.label,
    required this.currentValue,
    required this.maxLines,
  });

  @override
  State<_EditFieldForm> createState() => _EditFieldFormState();
}

class _EditFieldFormState extends State<_EditFieldForm> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);

    // Prevents focus race condition during sheet animation on Android OEM devices
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Edit ${widget.label}', style: context.text.headlineSmall),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          decoration: InputDecoration(hintText: 'Enter ${widget.label}'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}