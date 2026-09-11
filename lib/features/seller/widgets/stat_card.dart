import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtext;
  final Color? subtextColor;

  const StatCard({super.key, required this.label, required this.value, this.subtext, this.subtextColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label.toUpperCase(),
                  style: const TextStyle(fontSize: 11, color: AppColors.textGray, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontFamily: AppFonts.brand, fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink)),
          if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(subtext!, style: TextStyle(fontSize: 12, color: subtextColor ?? AppColors.textGray)),
          ],
        ],
      ),
    );
  }
}