import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanzee_app/data/models/auth_state.dart';
import 'package:yanzee_app/data/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _navigateNext();
  }

  Future<void> _restoreSession() async {
    try {
      // Render's free tier can take a while to wake up, so don't wait forever.
      await AuthService.restoreSession().timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
    } catch (_) {
      // Any failure just means the user starts logged out.
    }
  }

  Future<void> _navigateNext() async {
    // Show the splash for at least 2s while the session is restored.
    await Future.wait<void>([
      Future.delayed(const Duration(seconds: 2)),
      _restoreSession(),
    ]);
    if (!mounted) return;

    // Shop owner -> /seller-dashboard, customer or guest -> /home
    context.go(AuthState.instance.homeRoute);
  }

  Widget _dots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(right: 2),
          decoration: const BoxDecoration(
            color: AppColors.accentRed,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppColors.accentRed,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 40),
                child: _dots(),
              ),
              const SizedBox(height: 2),
              const Text('यांजी', style: AppTextStyles.splashDevanagari),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(right: 40),
                child: _dots(),
              ),
              const SizedBox(height: 1),
              const Text('YänZee', style: AppTextStyles.splashBrand),
              const SizedBox(height: 16),
              const Text('loading', style: AppTextStyles.loading),
            ],
          ),
        ),
      ),
    );
  }
}