import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/core/utils/app_snackbar.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/models/nepal_location_data.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_visual_panel.dart';
import 'package:yanzee_app/features/auth/screens/widgets/pill_text_form_field.dart';
import 'package:yanzee_app/features/auth/screens/widgets/searchable_select_field.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
import 'package:yanzee_app/features/wishlist/provider/wishlist_provider.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  static const routeName = '/signup';

  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _role = UserRole.customer;
  String? _gender;
  String? _province;
  String? _district;
  String? _city;

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  List<String> get _provinceOptions => nepalProvinces();
  List<String> get _districtOptions => nepalDistricts(_province);
  List<String> get _cityOptions => nepalCities(_province, _district);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onProvinceChanged(String? value) {
    setState(() {
      _province = value;
      _district = null;
      _city = null;
    });
  }

  void _onDistrictChanged(String? value) {
    setState(() {
      _district = value;
      _city = null;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppSnackBar.error(context, message);
    } else {
      AppSnackBar.success(context, message);
    }
  }

  String _genderForApi(String g) {
    switch (g) {
      case 'Male':
        return 'MALE';
      case 'Female':
        return 'FEMALE';
      default:
        return 'OTHER'; // confirm the exact value your backend accepts
    }
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_gender == null) {
      _showMessage('Please select a gender.', isError: true);
      return;
    }
    if (_province == null || _district == null || _city == null) {
      _showMessage('Please select your province, district and city.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.register({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phone': _phoneController.text.trim(),
        'gender': _genderForApi(_gender!),
        'role': _role, // CUSTOMER or SHOP_OWNER
        'address': _addressController.text.trim(),
        'city': _city,
        'province': _province,
        'district': _district,
        'country': nepalCountry,
      });

      // register returns no tokens, so log in right away
      await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(
        e is AuthException ? e.message : 'Something went wrong.',
        isError: true,
      );
      return;
    }

    ref.read(cartProvider.notifier).clear();
    debugPrint(
      'SIGNUP role=${AuthState.instance.user?.role} '
      'isShopOwner=${AuthState.instance.isShopOwner} '
      'route=${AuthState.instance.homeRoute}',
    );
    ref.read(wishlistProvider.notifier).clear();

    if (!mounted) return;
    setState(() => _isLoading = false);
    _showMessage('Account created successfully!');

    // CUSTOMER -> /home, SHOP_OWNER -> /seller-dashboard
    context.go(AuthState.instance.homeRoute);
  }

  void _goToLogin() {
    context.pushReplacement(LoginScreen.routeName);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.screenBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 850;

            if (!isWide) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _buildFormPanel(constraints.maxWidth),
                ),
              );
            }

            final cardWidth = constraints.maxWidth > 1100
                ? 1100.0
                : constraints.maxWidth;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AuthColors.screenBackground,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 55,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(flex: 48, child: AuthVisualPanel()),
                          Expanded(
                            flex: 52,
                            child: _buildFormPanel(cardWidth * 0.52),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AuthColors.pillText,
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AuthColors.required),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel(double panelWidth) {
    // Scales text slightly on small phones so nothing overflows.
    final scale = (panelWidth / 390).clamp(0.85, 1.0);
    final hPad = (panelWidth * 0.06).clamp(16.0, 28.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildBackButton(),
                ),
                const SizedBox(height: 24),

                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30 * scale,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Create a new account to get started and enjoy seamless access to our features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5 * scale,
                      height: 1.4,
                      color: AuthColors.subtitleGray,
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // ---------- Role ----------
                _sectionLabel('I want to sign up as'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: authPillShadow,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 0,
                    children: [
                      _roleOption(UserRole.customer, 'Customer'),
                      _roleOption(UserRole.shopOwner, 'Shop Owner'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ---------- Full name ----------
                PillTextFormField(
                  controller: _nameController,
                  hint: 'Full name',
                  icon: Icons.person_rounded,
                  textInputAction: TextInputAction.next,
                  validator: FormValidators.name,
                ),
                const SizedBox(height: 16),

                // ---------- Email ----------
                PillTextFormField(
                  controller: _emailController,
                  hint: 'Email address',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: FormValidators.email,
                ),
                const SizedBox(height: 16),

                // ---------- Phone ----------
                PillTextFormField(
                  controller: _phoneController,
                  hint: '10-digit phone number',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Phone number is required';
                    if (!RegExp(r'^\d{10}$').hasMatch(s)) {
                      return 'Enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ---------- Gender ----------
                _sectionLabel('Gender', required: true),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: authPillShadow,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 0,
                    children: [
                      _genderOption('Male'),
                      _genderOption('Female'),
                      _genderOption('Others'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ---------- Province / District / City (Nepal only) ----------
                // NOTE: still old style until searchable_select_field.dart is restyled
                SearchableSelectField(
                  label: 'Province',
                  options: _provinceOptions,
                  value: _province,
                  onChanged: _onProvinceChanged,
                  placeholder: 'Search or select province...',
                ),
                const SizedBox(height: 16),

                SearchableSelectField(
                  label: 'District',
                  options: _districtOptions,
                  value: _district,
                  onChanged: _onDistrictChanged,
                  enabled: _province != null,
                  placeholder: 'Search or select district...',
                  disabledPlaceholder: 'Select a province first',
                ),
                const SizedBox(height: 16),

                SearchableSelectField(
                  label: 'City',
                  options: _cityOptions,
                  value: _city,
                  onChanged: (v) => setState(() => _city = v),
                  enabled: _district != null,
                  placeholder: 'Search or select city...',
                  disabledPlaceholder: 'Select a district first',
                ),
                const SizedBox(height: 16),

                // ---------- Street address ----------
                PillTextFormField(
                  controller: _addressController,
                  hint: 'Street address (e.g. 123 Main Street)',
                  icon: Icons.location_on_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Address is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // ---------- Password ----------
                PillTextFormField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_rounded,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 20,
                      color: AuthColors.pillIcon,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  validator: FormValidators.password,
                ),
                const SizedBox(height: 16),

                // ---------- Confirm password ----------
                PillTextFormField(
                  controller: _confirmPasswordController,
                  hint: 'Confirm password',
                  icon: Icons.lock_rounded,
                  obscureText: !_showConfirmPassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 20,
                      color: AuthColors.pillIcon,
                    ),
                    onPressed: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    ),
                  ),
                  validator: FormValidators.confirmPassword,
                ),
                const SizedBox(height: 26),

                // ---------- Submit ----------
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: AuthColors.primary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthColors.primary,
                      disabledBackgroundColor: AuthColors.primary.withOpacity(
                        0.65,
                      ),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    style: TextStyle(
                      fontSize: 13 * scale,
                      color: AuthColors.pillText,
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account?  '),
                      TextSpan(
                        text: 'Sign In here',
                        style: const TextStyle(
                          color: AuthColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = _goToLogin,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleOption(String value, String label) {
    return InkWell(
      onTap: () => setState(() => _role = value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _role,
            activeColor: AuthColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (v) => setState(() => _role = v ?? _role),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: AuthColors.pillText),
          ),
        ],
      ),
    );
  }

  Widget _genderOption(String option) {
    return InkWell(
      onTap: () => setState(() => _gender = option),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: option,
            groupValue: _gender,
            activeColor: AuthColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (v) => setState(() => _gender = v),
          ),
          Text(
            option,
            style: const TextStyle(fontSize: 13.5, color: AuthColors.pillText),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _goBack,
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.chevron_left_rounded,
            size: 26,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
