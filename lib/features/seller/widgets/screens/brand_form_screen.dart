import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/brand.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_brands_provider.dart';

class BrandFormScreen extends ConsumerStatefulWidget {
  /// null = add a new brand, otherwise edit this one.
  final Brand? initial;
  const BrandFormScreen({super.key, this.initial});

  @override
  ConsumerState<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends ConsumerState<BrandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.initial?.description ?? '');
  late bool _isAvailable = widget.initial?.isAvailable ?? true;
  File? _logo;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
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

    final notifier = ref.read(sellerBrandsProvider.notifier);
    final name = _name.text.trim();
    final text = _description.text.trim();
    final description = text.isEmpty ? null : text;

    final error = _isEditing
        ? await notifier.updateBrand(
            widget.initial!,
            name: name,
            isAvailable: _isAvailable,
            logo: _logo,
            description: description,
          )
        : await notifier.createBrand(
            name: name,
            isAvailable: _isAvailable,
            logo: _logo,
            description: description,
          );

    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      AppToast.error(context, error);
      return;
    }
    AppToast.success(
      context,
      _isEditing ? 'Brand updated successfully' : 'Brand created successfully',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit brand' : 'Add brand')),
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
                      child: Center(
                        child: _LogoPickerTile(
                          file: _logo,
                          url: widget.initial?.logo,
                          enabled: !_saving,
                          onTap: _pickLogo,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SellerReveal(
                      index: 1,
                      child: SellerSectionCard(
                        icon: Iconsax.tag,
                        title: 'Brand details',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'This field is required'
                                      : null,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Brand name',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _description,
                              minLines: 3,
                              maxLines: 4,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              decoration: const InputDecoration(
                                labelText: 'Description (optional)',
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SellerReveal(
                      index: 2,
                      child: SellerSectionCard(
                        icon: Iconsax.eye,
                        title: 'Visibility',
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isAvailable,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _isAvailable = v),
                          title: const Text(
                            'Available to customers',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SellerBottomBar(
                label: _isEditing ? 'Save changes' : 'Add brand',
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

class _LogoPickerTile extends StatelessWidget {
  const _LogoPickerTile({
    required this.file,
    required this.url,
    required this.enabled,
    required this.onTap,
  });

  final File? file;
  final String? url;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasUrl = url != null && url!.isNotEmpty;
    final hasImage = file != null || hasUrl;

    Widget image() {
      if (file != null) {
        return Image.file(file!, fit: BoxFit.cover, cacheWidth: 360);
      }
      return Image.network(
        url!,
        fit: BoxFit.cover,
        cacheWidth: 360,
        errorBuilder: (_, __, ___) =>
            Container(color: scheme.surfaceContainerHighest),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Choose brand logo',
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
                child: hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          image(),
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
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.gallery_add,
                            size: 30,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add logo',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
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
          'Brand logo (optional)',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}