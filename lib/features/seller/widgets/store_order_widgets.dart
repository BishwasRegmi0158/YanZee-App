import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_widgets.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/data/models/store_order.dart';

/// Which pill colour an order status gets.
PillTone storeOrderStatusTone(String status) =>
    switch (status.toUpperCase()) {
      'PENDING' => PillTone.orange,
      'PROCESSING' => PillTone.blue,
      'DELIVERED' => PillTone.green,
      'CANCELLED' => PillTone.red,
      _ => PillTone.gray, // RETURNED and anything unknown
    };

/// Which pill colour a payment status gets.
PillTone storePaymentTone(String status) => switch (status.toUpperCase()) {
      'PAID' => PillTone.green,
      'PARTIAL_PAID' => PillTone.orange,
      'UNPAID' => PillTone.red,
      _ => PillTone.gray,
    };

/// Background and text colour of a pill tone, read from the theme.
(Color, Color) storePillColors(BuildContext context, PillTone tone) {
  final s = context.status;
  return switch (tone) {
    PillTone.green => (s.successBg, s.successFg),
    PillTone.red => (s.dangerBg, s.dangerFg),
    PillTone.blue => (s.infoBg, s.infoFg),
    PillTone.orange => (s.warningBg, s.warningFg),
    PillTone.gray => (s.neutralBg, s.neutralFg),
  };
}

/// Background and text colour of an order status.
(Color, Color) storeOrderStatusColors(BuildContext context, String status) =>
    storePillColors(context, storeOrderStatusTone(status));

/// Background and text colour of a payment status.
(Color, Color) storePaymentColors(BuildContext context, String status) =>
    storePillColors(context, storePaymentTone(status));

/// A small rounded label, with an optional dot.
class StorePill extends StatelessWidget {
  const StorePill({
    super.key,
    required this.text,
    required this.tone,
    this.dot = true,
  });

  final String text;
  final PillTone tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = storePillColors(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: Responsive.font(context, 10.5),
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class StoreOrderStatusPill extends StatelessWidget {
  const StoreOrderStatusPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    return StorePill(
      text: prettyEnum(status),
      tone: storeOrderStatusTone(status),
    );
  }
}

class StorePaymentPill extends StatelessWidget {
  const StorePaymentPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    return StorePill(
      text: prettyEnum(status),
      tone: storePaymentTone(status),
    );
  }
}

class StoreChannelPill extends StatelessWidget {
  const StoreChannelPill(this.channel, {super.key});

  final String channel;

  @override
  Widget build(BuildContext context) {
    return StorePill(
      text: channel == StoreOrderChannel.pos ? 'POS' : 'Admin',
      tone: PillTone.gray,
      dot: false,
    );
  }
}