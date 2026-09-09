import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

/// Placeholder — not part of the requested scope, but linked from
/// Settings so the row isn't a dead end. Fill in with real
/// change-password / 2FA / data controls when ready.
class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        title: const Text('Privacy & Security', style: TextStyle(color: AuthColors.textDark)),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Password, two-factor authentication, and data controls will live here.',
            style: TextStyle(color: AuthColors.textDark),
          ),
        ),
      ),
    );
  }
}