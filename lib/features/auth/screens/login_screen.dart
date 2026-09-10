import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_visual_panel.dart';
import 'package:yanzee_app/features/cart/provider/cart_provider.dart';
import 'package:yanzee_app/features/wishlist/provider/wishlist_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _error = null);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    final emailError = FormValidators.email(email);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.login(email, password);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e is AuthException
            ? e.message
            : 'Something went wrong. Please try again.';
      });
      return;
    }
    ref.read(cartProvider.notifier).clear();
    ref.read(wishlistProvider.notifier).clear();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/my-profile');
    }
  }

  void _goToSignup() {
    context.pushReplacement(SignupScreen.routeName);
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
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildFormPanel(showMobileBrand: true),
                  ),
                ),
              );
            }

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
                    child: SizedBox(
                      height: 620,
                      child: Row(
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
          constraints: const BoxConstraints(maxWidth: 440),
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
                'Welcome back',
                textAlign: showMobileBrand ? TextAlign.center : TextAlign.start,
                style: AuthTextStyles.heading,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your YanZee Collection account',
                textAlign: showMobileBrand ? TextAlign.center : TextAlign.start,
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
                          'Login',
                          style: AuthTextStyles.tabActive,
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _goToSignup,
                        borderRadius: BorderRadius.circular(7),
                        child: const Center(
                          child: Text('Signup', style: AuthTextStyles.tab),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AuthColors.errorBackground,
                    border: Border.all(color: AuthColors.errorBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⚠ $_error',
                    style: const TextStyle(
                      color: AuthColors.errorText,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              const Text('Email address', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                style: AuthTextStyles.inputText,
                onChanged: (_) => setState(() => _error = null),
                decoration: authInputDecoration(
                  hint: 'Enter your email',
                  prefixIcon: const Icon(
                    Icons.mail_outline,
                    size: 18,
                    color: AuthColors.iconMuted,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              const Text('Password', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                autofillHints: const [AutofillHints.password],
                style: AuthTextStyles.inputText,
                onChanged: (_) => setState(() => _error = null),
                decoration: authInputDecoration(
                  hint: 'Enter your password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: AuthColors.iconMuted,
                  ),
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
              ),

              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      // TODO: navigate to your forgot-password screen.
                    },
                    child: const Text(
                      'Forgot password?',
                      style: AuthTextStyles.forgotLink,
                    ),
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthColors.submitButton,
                    disabledBackgroundColor: AuthColors.submitButton
                        .withOpacity(0.65),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isLoading ? 'Logging in...' : 'Login',
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
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: 'Create account',
                        style: AuthTextStyles.switchLink,
                        recognizer: TapGestureRecognizer()..onTap = _goToSignup,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
