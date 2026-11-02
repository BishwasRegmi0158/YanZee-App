import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final s = context.status;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: s.errorBannerBg,
        border: Border.all(color: s.errorBannerBorder),
        borderRadius: BorderRadius.circular(AppTheme.rXl),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: s.dangerFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: s.dangerFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}