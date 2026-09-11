// features/seller/widgets/order_status_badge.dart
import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  (Color bg, Color fg) get _colors {
    switch (status) {
      case 'New':
        return (AppColors.gold.withOpacity(0.15), AppColors.gold);
      case 'Processing':
        return (const Color(0xFFDCEAFE), const Color(0xFF2563EB));
      case 'Ready':
        return (const Color(0xFFDCFCE7), const Color(0xFF16A34A));
      case 'On the way':
        return (const Color(0xFFFFEDD5), const Color(0xFFC2410C));
      case 'Delivered':
        return (AppColors.ink.withOpacity(0.08), AppColors.ink);
      case 'Cancelled':
        return (const Color(0xFFFEE2E2), const Color(0xFFDC2626));
      default:
        return (Colors.grey.shade200, Colors.grey.shade700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}