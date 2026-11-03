import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/auth/screens/signup_screen.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_error_banner.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_widgets.dart';

Future<bool> requireLogin(BuildContext context) async {
  if (AuthState.instance.isLoggedIn) return true;

  // Background and rounded top corners come from the global bottom sheet theme.
  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const LoginPromptSheet(),
  );

  final loggedIn = result ?? false;

  // A shop owner shouldn't stay on the customer screens.
  if (loggedIn && AuthState.instance.isShopOwner && context.mounted) {
    context.go('/seller-dashboard');
    return false; // stop the customer flow that asked for login
  }

  return loggedIn;
}

class LoginPromptSheet extends StatefulWidget {
  const LoginPromptSheet({super.key});

  @override
  State<LoginPromptSheet> createState() => _LoginPromptSheetState();
}

class _LoginPromptSheetState extends State<LoginPromptSheet> {
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

  Future<void> _handleLogin() async {
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

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop(true);
  }

  // push() (not go()) so the previous screen stays on the stack and
  // back navigation from Signup returns to it instead of crashing.
  void _goToSignup() {
    final router = GoRouter.of(context); // capture before popping
    Navigator.of(context).pop(false);
    router.push(SignupScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const AuthHeader(
                  title: 'Login required',
                  subtitle: 'Sign in to view this section',
                  scale: 0.85,
                ),
                const SizedBox(height: 24),

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
                  onSubmitted: (_) {
                    if (!_isLoading) _handleLogin();
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
                const SizedBox(height: 24),

                AuthSubmitButton(
                  label: 'Login',
                  loading: _isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 18),

                AuthSwitchLine(
                  prompt: "Don't have an account?",
                  action: 'Sign up here',
                  onTap: _goToSignup,
                ),
                SizedBox(height: viewInsets.bottom > 0 ? 8 : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}