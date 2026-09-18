import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/data/models/auth_state.dart';

import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/core/validation/form_validators.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import 'package:yanzee_app/features/auth/screens/signup_screen.dart';

/// Shows the login sheet if the user isn't logged in yet.
/// Returns true if the user is (or becomes) logged in, false if they dismissed it.
Future<bool> requireLogin(BuildContext context) async {
  if (AuthState.instance.isLoggedIn) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    // FIX (keyboard hidden behind fields): tab screens under
    // persistent_bottom_nav_bar each live in their own nested Navigator,
    // which carries a MediaQuery with viewInsets stripped out (so the
    // persistent nav bar itself doesn't jump around when some *other*
    // tab's keyboard opens). If this sheet attaches to that nested
    // Navigator, it inherits the broken MediaQuery and never sees the
    // real keyboard height — no amount of padding logic inside the sheet
    // can fix that. useRootNavigator forces the sheet onto the actual
    // root Navigator, which has the real, correct viewInsets.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const LoginPromptSheet(),
  );

  return result ?? false;
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
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DEDA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Login required',
                  style: AuthTextStyles.heading.copyWith(
                    fontSize: Responsive.font(context, 20),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to view this section',
                  style: AuthTextStyles.subheading.copyWith(
                    fontSize: Responsive.font(context, 13),
                  ),
                ),
                const SizedBox(height: 20),
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
                      style: TextStyle(
                        color: AuthColors.errorText,
                        fontSize: Responsive.font(context, 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
                Text('Email address', style: AuthTextStyles.fieldLabel),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: AuthTextStyles.inputText,
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
                Text('Password', style: AuthTextStyles.fieldLabel),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                  style: AuthTextStyles.inputText,
                  decoration: authInputDecoration(
                    hint: 'Enter your password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AuthColors.iconMuted,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 18,
                        color: AuthColors.iconMuted,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthColors.submitButton,
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
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: _goToSignup,
                    child: Text(
                      "Don't have an account? Create one",
                      style: AuthTextStyles.switchLink.copyWith(
                        fontSize: Responsive.font(context, 13),
                      ),
                    ),
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