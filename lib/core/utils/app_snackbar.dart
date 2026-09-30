import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/auth_theme.dart';

class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) => _show(
        context,
        message,
        AuthColors.primary,
        Icons.check_circle_rounded,
        const Duration(seconds: 3),
      );

  static void error(BuildContext context, String message) => _show(
        context,
        message,
        AuthColors.errorText,
        Icons.error_outline_rounded,
        const Duration(seconds: 5),
      );

  static void info(BuildContext context, String message) => _show(
        context,
        message,
        AuthColors.pillText,
        Icons.info_outline_rounded,
        const Duration(seconds: 4),
      );

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
    Duration duration,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          duration: duration,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}