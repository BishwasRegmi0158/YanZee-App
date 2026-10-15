import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/widgets/app_toast.dart';
import 'package:yanzee_app/data/models/customer.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_customers_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  /// null = add a new customer, otherwise edit this one.
  final Customer? initial;
  const CustomerFormScreen({super.key, this.initial});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.initial?.phone ?? '');
  late final TextEditingController _email =
      TextEditingController(text: widget.initial?.email ?? '');
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
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

  String? _emailRule(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null; // optional
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
        ? null
        : 'Enter a valid email';
  }

  String? _blankToNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final notifier = ref.read(sellerCustomersProvider.notifier);
    final name = _name.text.trim();
    final phone = _blankToNull(_phone.text);
    final email = _blankToNull(_email.text);

    final error = _isEditing
        ? await notifier.updateCustomer(
            widget.initial!,
            name: name,
            phone: phone,
            email: email,
          )
        : await notifier.create(name: name, phone: phone, email: email);

    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      AppToast.error(context, error);
      return;
    }
    AppToast.success(
      context,
      _isEditing ? 'Customer updated successfully' : 'Customer added successfully',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit customer' : 'Add customer'),
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
                      child: SellerSectionCard(
                        icon: Iconsax.user,
                        title: 'Customer details',
                        child: TextFormField(
                          controller: _name,
                          validator: _required,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Customer name',
                          ),
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
                              controller: _phone,
                              validator: _phoneRule,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                prefixIcon: Icon(Iconsax.call),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _email,
                              validator: _emailRule,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Iconsax.sms),
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
                label: _isEditing ? 'Save changes' : 'Add customer',
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