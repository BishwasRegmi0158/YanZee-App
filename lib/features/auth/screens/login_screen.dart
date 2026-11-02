import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_error_banner.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_visual_panel.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_widgets.dart';
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
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
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

    // Shop owner -> dashboard, customer -> back / home
    if (AuthState.instance.isShopOwner) {
      context.go('/seller-dashboard');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _goToSignup() {
    context.pushReplacement(SignupScreen.routeName);
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildFormPanel(constraints.maxWidth),
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
                    decoration: authCardDecoration(context),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: 620,
                      child: Row(
                        children: [
                          const Expanded(flex: 48, child: AuthVisualPanel()),
                          Expanded(
                            flex: 52,
                            child: SingleChildScrollView(
                              child: _buildFormPanel(
                                constraints.maxWidth * 0.5,
                              ),
                            ),
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
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AuthBackButton(onTap: _goBack),
              ),
              const SizedBox(height: 28),

              AuthHeader(
                title: 'Log in',
                subtitle:
                    'Enter your email and password to securely access your account.',
                scale: scale,
              ),
              const SizedBox(height: 28),

              if (_error != null) ...[
                AuthErrorBanner(_error!),
                const SizedBox(height: 16),
              ],

              AuthTextField(
                controller: _emailController,
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 16),

              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_rounded,
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) {
                  if (!_isLoading) _handleSubmit();
                },
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
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
              ),
              const SizedBox(height: 14),

              // Remember me + Forgot password
              Row(
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? false),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Remember me',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5 * scale,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      // TODO: navigate to your forgot-password screen.
                    },
                    child: Text(
                      'Forgot Password',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12.5 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              AuthSubmitButton(
                label: 'Login',
                loading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 20),

              AuthSwitchLine(
                prompt: "Don't have an account?",
                action: 'Sign up here',
                onTap: _goToSignup,
                scale: scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}