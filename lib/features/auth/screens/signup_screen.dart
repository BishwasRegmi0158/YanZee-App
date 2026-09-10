import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/models/location_data.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_visual_panel.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _gender;
  String? _countryCode;
  String? _province;
  String? _district;
  String? _city;

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  List<String> get _countryNames =>
      allowedCountries.map((code) => locationData[code]!.name).toList();

  String? get _countryName =>
      _countryCode != null ? locationData[_countryCode]!.name : null;

  bool get _hasDistrictSelect =>
      _countryCode != null && countryHasDistricts(_countryCode!);

  List<String> get _provinceOptions => getProvincesForCountry(_countryCode);

  List<String> get _districtOptions =>
      getDistrictsForProvince(_countryCode, _province);

  List<String> get _cityOptions => _hasDistrictSelect
      ? getCitiesForDistrict(_countryCode, _province, _district)
      : getCitiesForProvince(_countryCode, _province);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCountryChanged(String? name) {
    setState(() {
      _countryCode = name == null
          ? null
          : allowedCountries.firstWhere(
              (code) => locationData[code]!.name == name,
            );
      _province = null;
      _district = null;
      _city = null;
    });
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_gender == null) {
      _showMessage('Please select a gender.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }

    final payload = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'gender': _gender,
      'country': _countryName ?? '',
      'province': _province ?? '',
      'district': _district ?? '',
      'city': _city ?? '',
      'password': _passwordController.text,
    };

    // TODO: replace with your real signup API call.
    debugPrint('Submitted payload: $payload');

    AuthState.instance.login(
      UserProfile(
        name: payload['name'] as String,
        email: payload['email'] as String,
      ),
    );

    ref.read(cartProvider.notifier).clear();
    ref.read(wishlistProvider.notifier).clear();
    _showMessage('Account created successfully!');
    context.go('/my-profile');
  }

  void _goToLogin() {
    context.pushReplacement(LoginScreen.routeName);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/my-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 850;
            if (!isWide) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: _buildFormPanel(showMobileBrand: true),
                    ),
                  ),
                ),
              );
            }

            // Wide/desktop: keep the centered split-panel card.
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AuthColors.cardBackground,
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
                            child: _buildFormPanel(showMobileBrand: false),
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

  Widget _buildFormPanel({required bool showMobileBrand}) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBackButton(),
                const SizedBox(height: 12),

                if (showMobileBrand) ...[
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 35,
                          height: 35,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            'Y',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'YanZee Collection',
                          style: TextStyle(
                            color: AuthColors.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Text(
                  'Create your account',
                  textAlign: showMobileBrand
                      ? TextAlign.center
                      : TextAlign.start,
                  style: AuthTextStyles.heading,
                ),
                const SizedBox(height: 8),
                Text(
                  'Become a member of YanZee Collection',
                  textAlign: showMobileBrand
                      ? TextAlign.center
                      : TextAlign.start,
                  style: AuthTextStyles.subheading,
                ),
                const SizedBox(height: 22),

                Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AuthColors.tabsBackground,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _goToLogin,
                          borderRadius: BorderRadius.circular(7),
                          child: const Center(
                            child: Text('Login', style: AuthTextStyles.tab),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Signup',
                            style: AuthTextStyles.tabActive,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text.rich(
                  TextSpan(
                    style: AuthTextStyles.fieldLabel,
                    children: [
                      TextSpan(text: 'Full Name '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: AuthColors.required),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: AuthTextStyles.inputText,
                  decoration: authInputDecoration(hint: 'Enter your full name'),
                  validator: FormValidators.name,
                ),
                const SizedBox(height: 15),

                const Text.rich(
                  TextSpan(
                    style: AuthTextStyles.fieldLabel,
                    children: [
                      TextSpan(text: 'Email '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: AuthColors.required),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AuthTextStyles.inputText,
                  decoration: authInputDecoration(hint: 'Enter your email'),
                  validator: FormValidators.email,
                ),
                const SizedBox(height: 15),

                const Text.rich(
                  TextSpan(
                    style: AuthTextStyles.fieldLabel,
                    children: [
                      TextSpan(text: 'Gender '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: AuthColors.required),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 25,
                  runSpacing: 8,
                  children: [
                    _genderOption('Male'),
                    _genderOption('Female'),
                    _genderOption('Others'),
                  ],
                ),
                const SizedBox(height: 15),

                SearchableSelectField(
                  label: 'Country',
                  options: _countryNames,
                  value: _countryName,
                  onChanged: _onCountryChanged,
                  placeholder: 'Search or select country...',
                ),
                const SizedBox(height: 15),

                SearchableSelectField(
                  label: 'State / Province',
                  options: _provinceOptions,
                  value: _province,
                  onChanged: _onProvinceChanged,
                  enabled: _countryCode != null,
                  placeholder: 'Search or select state/province...',
                  disabledPlaceholder: 'Select a country first',
                ),
                const SizedBox(height: 15),

                if (_hasDistrictSelect) ...[
                  SearchableSelectField(
                    label: 'District',
                    options: _districtOptions,
                    value: _district,
                    onChanged: _onDistrictChanged,
                    enabled: _province != null,
                    placeholder: 'Search or select district...',
                    disabledPlaceholder: 'Select a province first',
                  ),
                  const SizedBox(height: 15),
                ],

                SearchableSelectField(
                  label: 'City',
                  options: _cityOptions,
                  value: _city,
                  onChanged: (v) => setState(() => _city = v),
                  enabled: _hasDistrictSelect
                      ? _district != null
                      : _province != null,
                  placeholder: 'Search or select city...',
                  disabledPlaceholder: _hasDistrictSelect
                      ? 'Select a district first'
                      : 'Select a province first',
                ),
                const SizedBox(height: 15),

                const Text.rich(
                  TextSpan(
                    style: AuthTextStyles.fieldLabel,
                    children: [
                      TextSpan(text: 'Password '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: AuthColors.required),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: AuthTextStyles.inputText,
                  decoration: authInputDecoration(
                    hint: 'Enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        size: 18,
                        color: AuthColors.iconMuted,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: FormValidators.password,
                ),
                const SizedBox(height: 15),

                const Text.rich(
                  TextSpan(
                    style: AuthTextStyles.fieldLabel,
                    children: [
                      TextSpan(text: 'Confirm Password '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: AuthColors.required),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  style: AuthTextStyles.inputText,
                  decoration: authInputDecoration(
                    hint: 'Confirm your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 18,
                        color: AuthColors.iconMuted,
                      ),
                      onPressed: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      ),
                    ),
                  ),
                  validator: FormValidators.confirmPassword,
                ),
                const SizedBox(height: 23),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthColors.submitButton,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign Up',
                      style: AuthTextStyles.submitButton,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AuthTextStyles.switchText,
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Login to your account',
                          style: AuthTextStyles.switchLink,
                          recognizer: TapGestureRecognizer()
                            ..onTap = _goToLogin,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderOption(String option) {
    final selected = _gender == option;
    return InkWell(
      onTap: () => setState(() => _gender = option),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: option,
            groupValue: _gender,
            activeColor: AuthColors.borderFocused,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => setState(() => _gender = v),
          ),
          Text(
            option,
            style: TextStyle(
              fontSize: 14,
              color: selected
                  ? const Color(0xFF222222)
                  : const Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: _goBack,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AuthColors.borderDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 17, color: AuthColors.textDark),
            SizedBox(width: 6),
            Text(
              'Back',
              style: TextStyle(fontSize: 14, color: AuthColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
