import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/data/models/auth_state.dart';

import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/auth/screens/signup_screen.dart';
import 'package:yanzee_app/features/auth/screens/widgets/auth_error_banner.dart';

Future<bool> requireLogin(BuildContext context) async {
  if (AuthState.instance.isLoggedIn) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AuthColors.screenBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
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

  Widget _pillBox(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: authPillShadow,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      color: const Color(0xFFD5D8DC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Login required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.font(context, 24),
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to view this section',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.font(context, 13.5),
                    height: 1.4,
                    color: AuthColors.subtitleGray,
                  ),
                ),
                const SizedBox(height: 24),

                if (_error != null) ...[
                  AuthErrorBanner(_error!),
                  const SizedBox(height: 16),
                ],

                _pillBox(
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AuthColors.pillText,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: authPillInputDecoration(
                      hint: 'Email address',
                      icon: Icons.email_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _pillBox(
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _isLoading ? null : _handleLogin(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AuthColors.pillText,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: authPillInputDecoration(
                      hint: 'Password',
                      icon: Icons.lock_rounded,
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
                    ),
                  ),
                ),
                const SizedBox(height: 24),

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
                    onPressed: _isLoading ? null : _handleLogin,
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
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    style: TextStyle(
                      fontSize: Responsive.font(context, 13),
                      color: AuthColors.pillText,
                    ),
                    children: [
                      const TextSpan(text: "Don't have an account?  "),
                      TextSpan(
                        text: 'Sign Up here',
                        style: const TextStyle(
                          color: AuthColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = _goToSignup,
                      ),
                    ],
                  ),
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
