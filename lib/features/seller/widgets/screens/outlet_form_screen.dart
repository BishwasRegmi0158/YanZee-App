import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/outlet.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_outlets_provider.dart';

class OutletFormScreen extends ConsumerStatefulWidget {
  /// null = add a new outlet, otherwise edit this one.
  final Outlet? initial;
  const OutletFormScreen({super.key, this.initial});

  @override
  ConsumerState<OutletFormScreen> createState() => _OutletFormScreenState();
}

class _OutletFormScreenState extends ConsumerState<OutletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _address =
      TextEditingController(text: widget.initial?.address ?? '');
  late final TextEditingController _person =
      TextEditingController(text: widget.initial?.contactPerson ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.initial?.contactPhone ?? '');
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _person.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _phoneRule(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null; // optional
    return RegExp(r'^\d{10}$').hasMatch(s)
        ? null
        : 'Enter a valid 10-digit phone number';
  }

  String? _blankToNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final notifier = ref.read(sellerOutletsProvider.notifier);
    final name = _name.text.trim();
    final address = _address.text.trim();
    final person = _blankToNull(_person.text);
    final phone = _blankToNull(_phone.text);

    final error = _isEditing
        ? await notifier.updateOutlet(
            widget.initial!,
            name: name,
            address: address,
            contactPerson: person,
            contactPhone: phone,
          )
        : await notifier.create(
            name: name,
            address: address,
            contactPerson: person,
            contactPhone: phone,
          );

    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      AppToast.error(context, error);
      return;
    }
    AppToast.success(
      context,
      _isEditing ? 'Outlet updated successfully' : 'Outlet created successfully',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit outlet' : 'Add outlet')),
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
                      child: SellerSectionCard(
                        icon: Iconsax.shop,
                        title: 'Outlet details',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              validator: _required,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Outlet name',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _address,
                              validator: _required,
                              minLines: 2,
                              maxLines: 3,
                              keyboardType: TextInputType.streetAddress,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SellerReveal(
                      index: 1,
                      child: SellerSectionCard(
                        icon: Iconsax.call,
                        title: 'Contact (optional)',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _person,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Contact person',
                                prefixIcon: Icon(Iconsax.user),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phone,
                              validator: _phoneRule,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Contact phone',
                                prefixIcon: Icon(Iconsax.call),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SellerBottomBar(
                label: _isEditing ? 'Save changes' : 'Add outlet',
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