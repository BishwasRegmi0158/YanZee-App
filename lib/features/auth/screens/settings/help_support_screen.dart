import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

/// Requires the `url_launcher` package (add to pubspec.yaml) to place
/// the phone call. TODO: replace with YanZee's real support number.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _supportNumber = '+9779860573543';

  Future<void> _callSupport(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _supportNumber);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        title: const Text('Help & Support', style: TextStyle(color: AuthColors.textDark)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDEBE7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_outlined, color: AuthColors.textDark, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer support', style: TextStyle(fontWeight: FontWeight.w700, color: AuthColors.textDark)),
                        const SizedBox(height: 2),
                        Text(_supportNumber, style: const TextStyle(fontSize: 13, color: Color(0xFF9A9A9A))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: AuthColors.submitButton, shape: const CircleBorder()),
                    onPressed: () => _callSupport(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}