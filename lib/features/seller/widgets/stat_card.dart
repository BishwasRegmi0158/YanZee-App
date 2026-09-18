import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/utils/responsive.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtext;
  final Color? subtextColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtext,
    this.subtextColor,
  });

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // nudge the dot down so it aligns with the first line
                // now that the label can wrap to two lines
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Fix: capSystemScale: false stops this from being inflated
              // by a device's larger accessibility text-scale setting
              // (e.g. Huawei EMUI), which was the real reason "TOTAL
              // REVENUE" and "AVG ORDER VALUE" were truncating on that
              // phone but not the emulator. Letting it wrap to 2 lines
              // instead of forcing 1 + ellipsis means the full label is
              // always readable instead of getting cut off.
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.font(
                      context,
                      10.5,
                      capSystemScale: false,
                    ),
                    height: 1.15,
                    color: AppColors.ink.withOpacity(0.62),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                fontFamily: 'Arial',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(
              subtext!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.font(
                  context,
                  12,
                  capSystemScale: false,
                ),
                fontWeight: FontWeight.w500,
                color: subtextColor ?? AppColors.ink.withOpacity(0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}