import 'package:flutter/material.dart';
import 'app_status_colors.dart';
import 'app_theme.dart';

enum PillTone { green, red, blue, orange, gray }

/// Small rounded label (website: StatusPill).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = PillTone.gray});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final s = context.status;
    final (bg, fg) = switch (tone) {
      PillTone.green => (s.successBg, s.successFg),
      PillTone.red => (s.dangerBg, s.dangerFg),
      PillTone.blue => (s.infoBg, s.infoFg),
      PillTone.orange => (s.warningBg, s.warningFg),
      PillTone.gray => (s.neutralBg, s.neutralFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

/// Red message box (website: ErrorBanner).
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    final s = context.status;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: s.errorBannerBg,
        border: Border.all(color: s.errorBannerBorder),
        borderRadius: BorderRadius.circular(AppTheme.rXl),
      ),
      child: Text(
        '⚠ $message',
        style: TextStyle(fontSize: 14, color: s.dangerFg),
      ),
    );
  }
}