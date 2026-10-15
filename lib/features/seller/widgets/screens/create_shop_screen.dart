import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/models/seller_shop.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

class CreateShopScreen extends ConsumerStatefulWidget {
  /// true when opened from the drawer to add another shop.
  final bool isAdditional;
  const CreateShopScreen({super.key, this.isAdditional = false});

  @override
  ConsumerState<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends ConsumerState<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  late final TextEditingController _email = TextEditingController(
    text: AuthState.instance.user?.email ?? '',
  );
  late final TextEditingController _phone = TextEditingController(
    text: AuthState.instance.user?.phone ?? '',
  );
  String? _category;
  File? _logo;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) setState(() => _logo = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final api = ref.read(shopApiServiceProvider);
      final shop = await api.createShop(
        name: _name.text.trim(),
        category: _category!,
        contactEmail: _email.text.trim(),
        contactPhone: _phone.text.trim(),
        storeAddress: _address.text.trim(),
      );

      // Optional logo: the server saves it on the store that was just made.
      var logoFailed = false;
      if (_logo != null) {
        try {
          await api.uploadStoreLogo(shop.id, _logo!);
        } catch (_) {
          logoFailed = true;
        }
      }
      const logoWarning =
          'Shop created, but the logo could not be uploaded. '
          'You can add it later in the Store tab.';

      if (widget.isAdditional) {
        if (!mounted) return;
        // Make the new shop the active one, then reload the list.
        ref.read(selectedShopIdProvider.notifier).state = shop.id;
        ref.invalidate(myShopsProvider);
        if (logoFailed) {
          AppToast.warning(context, logoWarning);
        } else {
          AppToast.success(context, 'Shop created successfully');
        }
        Navigator.of(context).pop();
      } else {
        if (logoFailed && mounted) AppToast.warning(context, logoWarning);
        // The gate reloads the store and switches to the dashboard.
        ref.invalidate(myShopsProvider);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, e);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    context.go('/home');
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _emailRule(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _phoneRule(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'This field is required';
    return RegExp(r'^\d{10}$').hasMatch(s)
        ? null
        : 'Enter a valid 10-digit phone number';
  }

  @override
  Widget build(BuildContext context) {
    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: widget.isAdditional,
          title: Text(
            widget.isAdditional ? 'Create new shop' : 'Set up your store',
          ),
          actions: widget.isAdditional
              ? null
              : [
                  TextButton(
                    onPressed: _saving ? null : _logout,
                    child: const Text('Log out'),
                  ),
                  const SizedBox(width: 8),
                ],
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    SellerReveal(
                      index: 0,
                      child: _ImagePickerHeader(
                        logo: _logo,
                        enabled: !_saving,
                        onPick: _pickLogo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SellerReveal(
                      index: 1,
                      child: _IntroText(
                        widget.isAdditional
                            ? 'Add another store to your account. You can edit these details later in the Store tab.'
                            : 'Create your store to start selling. You can edit these details later in the Store tab.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SellerReveal(
                      index: 2,
                      child: SellerSectionCard(
                        icon: Iconsax.shop,
                        title: 'Basic info',
                        child: TextFormField(
                          controller: _name,
                          validator: _required,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Store name',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SellerReveal(
                      index: 3,
                      child: SellerSectionCard(
                        icon: Iconsax.category,
                        title: 'Category',
                        child: _CategoryChips(
                          selected: _category,
                          onSelected: (c) => setState(() => _category = c),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SellerReveal(
                      index: 4,
                      child: SellerSectionCard(
                        icon: Iconsax.call,
                        title: 'Contact',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              validator: _emailRule,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Contact email',
                                prefixIcon: Icon(Iconsax.sms),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phone,
                              validator: _phoneRule,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Contact phone',
                                prefixIcon: Icon(Iconsax.call),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SellerReveal(
                      index: 5,
                      child: SellerSectionCard(
                        icon: Iconsax.location,
                        title: 'Location',
                        child: TextFormField(
                          controller: _address,
                          validator: _required,
                          minLines: 2,
                          maxLines: 3,
                          keyboardType: TextInputType.streetAddress,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Store address',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SellerBottomBar(
                label: 'Create shop',
                saving: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round logo picker (no banner behind it).
class _ImagePickerHeader extends StatelessWidget {
  const _ImagePickerHeader({
    required this.logo,
    required this.enabled,
    required this.onPick,
  });

  final File? logo;
  final bool enabled;
  final VoidCallback onPick;

  static const double _avatarSize = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ring = theme.scaffoldBackgroundColor;

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Choose store logo',
          child: GestureDetector(
            onTap: enabled ? onPick : null,
            child: SizedBox(
              width: _avatarSize,
              height: _avatarSize,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CircleAvatar(
                      backgroundColor: scheme.surfaceContainerHighest,
                      backgroundImage: logo == null ? null : FileImage(logo!),
                      child: logo == null
                          ? Icon(
                              Iconsax.shop,
                              size: 32,
                              color: scheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary,
                        border: Border.all(color: ring, width: 2),
                      ),
                      child: Icon(
                        Iconsax.camera,
                        size: 14,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Store logo (optional)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _IntroText extends StatelessWidget {
  const _IntroText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Category picker as a dropdown. a category is required.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Softer hover/press colors inside the open menu (instead of dark grey).
    final menuTheme = theme.copyWith(
      highlightColor: scheme.primary.withValues(alpha: 0.06),
      splashColor: scheme.primary.withValues(alpha: 0.08),
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
    );

    return Theme(
      data: menuTheme,
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        isExpanded: true,
        borderRadius: BorderRadius.circular(16),
        dropdownColor: scheme.surfaceContainerLowest,
        elevation: 3,
        menuMaxHeight: 320,
        icon: Icon(Iconsax.arrow_down_1, size: 18, color: scheme.onSurfaceVariant),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(labelText: 'Category'),
        // What the closed field shows: just the name.
        selectedItemBuilder: (context) => [
          for (final c in kStoreCategories)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                storeCategoryLabel(c),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        // What the open list shows: name + a tick on the chosen one.
        items: [
          for (final c in kStoreCategories)
            DropdownMenuItem(
              value: c,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      storeCategoryLabel(c),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            c == selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (c == selected)
                    Icon(Iconsax.tick_circle5, size: 18, color: scheme.primary),
                ],
              ),
            ),
        ],
        onChanged: (v) {
          if (v != null) onSelected(v);
        },
        validator: (v) => v == null ? 'Select a category' : null,
      ),
    );
  }
}