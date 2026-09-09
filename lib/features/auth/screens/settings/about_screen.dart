import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        title: const Text('About YanZee', style: TextStyle(color: AuthColors.textDark)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: const Text('Y', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text('YanZee Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AuthColors.textDark)),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: Color(0xFF9A9A9A))),
            ),
            const SizedBox(height: 24),
            // TODO: replace with YanZee's real company description.
            const Text(
              'YanZee Collection curates fashion, beauty, and lifestyle products '
              'for people who care about quality and design. We work with a '
              'growing set of vendors to bring you a thoughtfully chosen catalog, '
              'with easy tracking, secure payments, and support that actually helps.',
              style: TextStyle(fontSize: 14, height: 1.5, color: AuthColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}