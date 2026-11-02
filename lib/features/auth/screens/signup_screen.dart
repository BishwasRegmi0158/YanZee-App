import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/utils/app_snackbar.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_visual_panel.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_widgets.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppSnackBar.error(context, message);
    } else {
      AppSnackBar.success(context, message);
    }
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Same body as the Postman request. The backend assigns the role (OWNER).
      await AuthService.register({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phone': _phoneController.text.trim(),
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
    ref.read(wishlistProvider.notifier).clear();

    if (!mounted) return;
    setState(() => _isLoading = false);
    _showMessage('Account created successfully!');

    // OWNER -> /seller-dashboard
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

            final cardWidth =
                constraints.maxWidth > 1100 ? 1100.0 : constraints.maxWidth;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Container(
                    decoration: authCardDecoration(context),
                    clipBehavior: Clip.antiAlias,
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

  Widget _buildFormPanel(double panelWidth) {
    // Scales text slightly on small phones so nothing overflows.
    final double scale = (panelWidth / 390).clamp(0.85, 1.0).toDouble();
    final double hPad = (panelWidth * 0.06).clamp(16.0, 28.0).toDouble();
    final colors = context.colors;

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
                  child: AuthBackButton(onTap: _goBack),
                ),
                const SizedBox(height: 24),

                AuthHeader(
                  title: 'Create Account',
                  subtitle:
                      'Create a new account to get started and enjoy seamless access to our features.',
                  scale: scale,
                ),
                const SizedBox(height: 26),

                AuthTextField(
                  controller: _nameController,
                  label: 'Full name',
                  hint: 'Enter your full name',
                  icon: Icons.person_rounded,
                  textInputAction: TextInputAction.next,
                  validator: FormValidators.name,
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  controller: _emailController,
                  label: 'Email address',
                  hint: 'you@example.com',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: FormValidators.email,
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  controller: _phoneController,
                  label: 'Phone number',
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
                const SizedBox(height: 16),

                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a password',
                  icon: Icons.lock_rounded,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  validator: FormValidators.password,
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_rounded,
                  obscureText: !_showConfirmPassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    ),
                  ),
                  validator: FormValidators.confirmPassword,
                ),
                const SizedBox(height: 26),

                AuthSubmitButton(
                  label: 'Create Account',
                  loading: _isLoading,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 20),

                AuthSwitchLine(
                  prompt: 'Already have an account?',
                  action: 'Sign in here',
                  onTap: _goToLogin,
                  scale: scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}