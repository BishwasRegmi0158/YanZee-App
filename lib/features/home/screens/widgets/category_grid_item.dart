import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';

class CategoryGridItem extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback? onTap;

  const CategoryGridItem({
    super.key,
    required this.emoji,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.rXl),
              border: Border.all(color: colors.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}