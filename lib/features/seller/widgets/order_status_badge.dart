import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_widgets.dart';

/// Maps a seller order status to a pill colour.
PillTone orderStatusTone(String status) {
  switch (status) {
    case 'Delivered':
      return PillTone.green;
    case 'On its way':
    case 'Processing':
      return PillTone.blue;
    case 'Ready':
      return PillTone.gray;
    case 'Declined':
      return PillTone.red;
    default: // New
      return PillTone.orange;
  }
}

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: status, tone: orderStatusTone(status));
  }
}