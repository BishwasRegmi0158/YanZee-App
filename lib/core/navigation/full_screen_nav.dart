// lib/core/navigation/full_screen_nav.dart
import 'package:flutter/material.dart';

/// Pushes [screen] on the ROOT navigator instead of the nearest one.
///
/// Use this for any screen that should cover the entire app — including
/// the bottom navigation bar — such as account sub-screens (My Profile,
/// My Address, My Orders, My Cards, Settings and its sub-pages) and
/// full-screen image previews.
///
/// Without `rootNavigator: true`, a push from inside a bottom-nav shell
/// (e.g. a go_router StatefulShellRoute) lands on the shell's own nested
/// Navigator, so the bottom bar — which lives outside that Navigator —
/// stays visible and tappable on top of the new screen.
Future<T?> pushFullScreen<T>(BuildContext context, Widget screen) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(builder: (_) => screen),
  );
}