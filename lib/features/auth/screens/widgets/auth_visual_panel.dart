import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';

class AuthVisualPanel extends StatelessWidget {
  const AuthVisualPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onDark = colors.onInverseSurface;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomLeft: Radius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.inverseSurface, colors.scrim],
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: onDark.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
              child: Text(
                'Y',
                style: context.text.headlineMedium?.copyWith(
                  fontSize: 28,
                  color: onDark,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'YanZee Collection',
              textAlign: TextAlign.center,
              style: context.text.headlineMedium?.copyWith(
                fontSize: 26,
                color: onDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Fashion, beauty, and lifestyle, curated for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onDark.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}