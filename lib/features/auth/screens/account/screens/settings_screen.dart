import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';
import 'package:yanzee_app/features/auth/screens/settings/about_screen.dart';
import 'package:yanzee_app/features/auth/screens/settings/help_support_screen.dart';
import 'package:yanzee_app/features/auth/screens/settings/language_screen.dart';
import 'package:yanzee_app/features/auth/screens/settings/notifications_screen.dart';
import 'package:yanzee_app/features/auth/screens/settings/privacy_security_screen.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        title: const Text('Settings', style: TextStyle(color: AuthColors.textDark)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _row(context, 'Notifications', const NotificationsScreen()),
            _row(context, 'Privacy & Security', const PrivacySecurityScreen()),
            _row(context, 'Language', const LanguageScreen()),
            _row(context, 'Help & Support', const HelpSupportScreen()),
            _row(context, 'About YanZee', const AboutScreen()),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, Widget destination) {
    return Column(
      children: [
        ListTile(
          title: Text(label, style: const TextStyle(fontSize: 15, color: AuthColors.textDark)),
          trailing: const Icon(Icons.chevron_right, color: AuthColors.iconMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination)),
        ),
        const Divider(height: 1, color: Color(0xFFEDEBE7), indent: 16, endIndent: 16),
      ],
    );
  }
}