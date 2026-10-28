import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static const double _baseWidth = 390.0;

  // Tighter scale limits for typography to prevent text ballooning
  static const double _minScale = 0.78;
  static const double _maxScale = 1.05;

  /// Device scale factor. Uses the shorter side of the screen, so rotating a
  /// phone to landscape does not change the size of the UI.
  static double scale(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    return (shortest / _baseWidth).clamp(_minScale, _maxScale);
  }

  /// Responsive font size: scales with the screen only.
  /// The user's system font size is applied once, by Flutter's Text widget,
  /// and capped app-wide in MaterialApp.builder. [capSystemScale] is kept so
  /// existing calls still compile; it no longer does anything.
  static double font(
    BuildContext context,
    double base, {
    bool capSystemScale = true,
  }) =>
      base * scale(context);

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