import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

/// Local selection only — hook `_selected` into your real localization
/// (e.g. flutter_localizations / intl) setup when that's wired in.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _languages = ['English', 'नेपाली (Nepali)', 'हिन्दी (Hindi)'];
  String _selected = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AuthColors.pageBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textDark),
        title: const Text('Language', style: TextStyle(color: AuthColors.textDark)),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            for (final lang in _languages)
              RadioListTile<String>(
                title: Text(lang),
                value: lang,
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v!),
              ),
          ],
        ),
      ),
    );
  }
}