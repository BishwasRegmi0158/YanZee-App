import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontFamily: AppFonts.brand,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }
}