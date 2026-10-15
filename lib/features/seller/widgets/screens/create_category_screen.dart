import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/services/category_api_service.dart';
import 'package:yanzee_app/features/seller/widgets/providers/my_shop_provider.dart';

class CreateCategoryScreen extends ConsumerStatefulWidget {
  /// false = full screen (default, what your drawer uses today).
  /// true  = laid out as a bottom sheet.
  final bool asSheet;
  const CreateCategoryScreen({super.key, this.asSheet = false});

  /// Optional: open the form as a bottom sheet instead of a full screen.
  static Future<void> showAsSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateCategoryScreen(asSheet: true),
    );
  }

  @override
  ConsumerState<CreateCategoryScreen> createState() =>
      _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends ConsumerState<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  File? _image;
  bool _isAvailable = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) setState(() => _image = File(picked.path));
  }

  void _snack(String message) => AppToast.error(context, message);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final storeId = ref.read(myShopProvider).value?.id;
    if (storeId == null || storeId.isEmpty) {
      _snack('No store loaded.');
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(categoryApiServiceProvider);

      // 1) upload the image, 2) put its URL in the create request
      String? imageUrl;
      if (_image != null) {
        imageUrl = await api.uploadCategoryImage(storeId, _image!);
      }

      final description = _description.text.trim();
      await api.createCategory(
        storeId,
        name: _name.text.trim(),
        isAvailable: _isAvailable,
        image: imageUrl,
        description: description.isEmpty ? null : description,
      );

      if (!mounted) return;
      AppToast.success(context, 'Category created successfully');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// The form content, shared by the full-screen and the sheet layout.
  List<Widget> _fields() => [
    Center(
      child: _ImagePickerTile(
        image: _image,
        enabled: !_saving,
        onTap: _pickImage,
      ),
    ),
    const SizedBox(height: 24),
    _CategoryPreviewChip(
      nameController: _name,
      image: _image,
      isAvailable: _isAvailable,
    ),
    const SizedBox(height: 24),
    TextFormField(
      controller: _name,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'This field is required' : null,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Category name',
        prefixIcon: Icon(Iconsax.category),
      ),
    ),
    const SizedBox(height: 16),
    TextFormField(
      controller: _description,
      minLines: 3,
      maxLines: 3,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.newline,
      decoration: const InputDecoration(
        labelText: 'Description (optional)',
        alignLabelWithHint: true,
      ),
    ),
    const SizedBox(height: 8),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _isAvailable,
      onChanged: _saving ? null : (v) => setState(() => _isAvailable = v),
      title: const Text(
        'Available to customers',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.asSheet) return _buildSheet(context);

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Create category')),
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
                  children: _fields(),
                ),
              ),
              SellerBottomBar(
                label: 'Create category',
                saving: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(BuildContext context) {
    return SellerFormTheme(
      child: _SheetFrame(
        child: Padding(
          // Lifts the sheet above the keyboard.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHeader(
                  onClose: _saving ? null : () => Navigator.of(context).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(children: _fields()),
                  ),
                ),
                SellerBottomBar(
                  label: 'Create category',
                  saving: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded top corners + the themed background for the bottom-sheet layout.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Create category',
                  style: theme.appBarTheme.titleTextStyle,
                ),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'Close',
                icon: const Icon(Iconsax.close_circle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tap to choose the category image.
class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
    required this.image,
    required this.enabled,
    required this.onTap,
  });

  final File? image;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Choose category image',
          child: Material(
            color: scheme.surfaceContainerLowest,
            elevation: 1,
            shadowColor: scheme.shadow.withValues(alpha: 0.12),
            surfaceTintColor: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onTap : null,
              child: SizedBox(
                width: 120,
                height: 120,
                child: image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.gallery_add,
                            size: 30,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add image',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            image!,
                            fit: BoxFit.cover,
                            cacheWidth: 360,
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.primary,
                              ),
                              child: Icon(
                                Iconsax.edit_2,
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
        ),
        const SizedBox(height: 8),
        Text(
          'Category image (optional)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Shows how the category will look. Updates live as you type.
class _CategoryPreviewChip extends StatelessWidget {
  const _CategoryPreviewChip({
    required this.nameController,
    required this.image,
    required this.isAvailable,
  });

  final TextEditingController nameController;
  final File? image;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          'Preview',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: nameController,
          builder: (context, value, _) {
            final name = value.text.trim();
            final label = name.isEmpty ? 'Category name' : name;

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isAvailable ? 1 : 0.5,
              child: Chip(
                label: Text(
                  isAvailable ? label : '$label · Unavailable',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}