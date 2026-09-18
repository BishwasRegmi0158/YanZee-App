import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static const double _baseWidth = 390.0;

  // Tighter scale limits for typography to prevent text ballooning
  static const double _minScale = 0.78;
  static const double _maxScale = 1.05;

  /// Global device scale factor based on screen width
  static double scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / _baseWidth).clamp(_minScale, _maxScale);
  }

  /// Responsive Font Size
  /// Caps system text scaling factor when capSystemScale is true
  static double font(BuildContext context, double base, {bool capSystemScale = true}) {
    final widthScaled = base * scale(context);

    if (!capSystemScale) return widthScaled;

    final systemTextScaler = MediaQuery.textScalerOf(context);
    final clampedScaleFactor = systemTextScaler.scale(1.0).clamp(0.9, 1.15);

    return TextScaler.linear(clampedScaleFactor).scale(widthScaled);
  }

  /// Responsive Spacing & Padding
  static double space(BuildContext context, double base) {
    final s = scale(context).clamp(0.85, 1.08);
    return base * s;
  }

  /// Screen checks
  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  static bool isVerySmallPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 340;
}