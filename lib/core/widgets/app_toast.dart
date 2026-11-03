import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';

enum ToastType { success, error, warning, info }

/// One place for every pop-up message in the app.
///
///   AppToast.success(context, 'Outlet created successfully');
///   AppToast.error(context, error);            // String or exception
///   AppToast.warning(context, '...');
///   AppToast.info(context, '...');
///   AppToast.result(context, error: error, success: 'Saved successfully');
///
/// Only one pop-up is visible at a time; a new one replaces the old one.
/// Tap it or swipe it up to dismiss it early.
class AppToast {
  AppToast._();

  // How long each type stays on screen.
  static const Duration successDuration = Duration(seconds: 2);
  static const Duration infoDuration = Duration(seconds: 3);
  static const Duration warningDuration = Duration(seconds: 4);
  static const Duration errorDuration = Duration(seconds: 5);

  static _ToastHandle? _current;

  static void success(BuildContext context, String message) =>
      _show(context, message, ToastType.success);

  /// [message] can be a String or an exception ("Exception: " is removed).
  static void error(BuildContext context, Object message) =>
      _show(context, _clean(message), ToastType.error);

  static void warning(BuildContext context, String message) =>
      _show(context, message, ToastType.warning);

  static void info(BuildContext context, String message) =>
      _show(context, message, ToastType.info);

  /// Red when [error] is not null, otherwise green with [success].
  static void result(
    BuildContext context, {
    required String? error,
    required String success,
  }) {
    if (error != null) {
      AppToast.error(context, error);
    } else {
      AppToast.success(context, success);
    }
  }

  static String _clean(Object message) =>
      message.toString().replaceFirst('Exception: ', '').trim();

  static Duration _durationOf(ToastType type) => switch (type) {
        ToastType.success => successDuration,
        ToastType.info => infoDuration,
        ToastType.warning => warningDuration,
        ToastType.error => errorDuration,
      };

  static void _show(BuildContext context, String message, ToastType type) {
    final text = message.trim();
    if (text.isEmpty || !context.mounted) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Only one pop-up at a time.
    _current?.close();

    final handle = _ToastHandle();
    handle.entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: text,
        type: type,
        duration: _durationOf(type),
        onClosed: handle.close,
      ),
    );
    _current = handle;
    overlay.insert(handle.entry);
  }
}

class _ToastHandle {
  late final OverlayEntry entry;
  bool _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;
    if (identical(AppToast._current, this)) AppToast._current = null;
    entry.remove();
    entry.dispose();
  }
}

/// Colours and icon of one toast type, read from the theme so the pop-ups
/// always match the rest of the app.
class _ToastStyle {
  const _ToastStyle(this.background, this.foreground, this.icon);

  final Color background;
  final Color foreground;
  final IconData icon;

  // Every background keeps its text above the 4.5:1 contrast ratio.
  static _ToastStyle of(BuildContext context, ToastType type) {
    final colors = context.colors;
    final status = context.status;
    return switch (type) {
      ToastType.success => _ToastStyle(
          status.successFg,
          colors.onPrimary,
          Icons.check_circle_rounded,
        ),
      ToastType.error => _ToastStyle(
          status.dangerFg,
          colors.onPrimary,
          Icons.error_rounded,
        ),
      ToastType.warning => _ToastStyle(
          status.warningFg,
          colors.onPrimary,
          Icons.warning_amber_rounded,
        ),
      ToastType.info => _ToastStyle(
          colors.inverseSurface,
          colors.onInverseSurface,
          Icons.info_rounded,
        ),
    };
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.message,
    required this.type,
    required this.duration,
    required this.onClosed,
  });

  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onClosed;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.6),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (mounted) await _controller.reverse();
    widget.onClosed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _ToastStyle.of(context, widget.type);
    final top = MediaQuery.paddingOf(context).top + 12;

    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _controller,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Semantics(
                liveRegion: true,
                container: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) < -150) _close();
                  },
                  child: Material(
                    color: style.background,
                    elevation: 6,
                    shadowColor: context.colors.shadow.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppTheme.rXl),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.foreground, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: style.foreground,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Dismiss',
                            child: InkResponse(
                              onTap: _close,
                              radius: 20,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: style.foreground.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}