import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Flies [child] from [startKey]'s position to [endKey]'s position with a
/// pop-then-arc-then-shrink motion. Works for any "add to X" action —
/// cart, wishlist, etc.
class FlyToTargetAnimator {
  static void fly({
    required BuildContext context,
    required GlobalKey startKey,
    required GlobalKey endKey,
    required Widget child,
    double size = 46,
    Duration duration = const Duration(milliseconds: 700),
    VoidCallback? onLanded,
  }) {
    final overlayState = Overlay.of(context);
    final startBox = startKey.currentContext?.findRenderObject() as RenderBox?;
    final endBox = endKey.currentContext?.findRenderObject() as RenderBox?;
    if (startBox == null || endBox == null) return;

    final overlayBox = overlayState.context.findRenderObject() as RenderBox;
    final start = startBox.localToGlobal(
      startBox.size.center(Offset.zero),
      ancestor: overlayBox,
    );
    final end = endBox.localToGlobal(
      endBox.size.center(Offset.zero),
      ancestor: overlayBox,
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlyingItem(
        start: start,
        end: end,
        size: size,
        duration: duration,
        child: child,
        onComplete: () {
          entry.remove();
          onLanded?.call();
        },
      ),
    );
    overlayState.insert(entry);
  }
}

class _FlyingItem extends StatefulWidget {
  const _FlyingItem({
    required this.start,
    required this.end,
    required this.size,
    required this.duration,
    required this.child,
    required this.onComplete,
  });

  final Offset start;
  final Offset end;
  final double size;
  final Duration duration;
  final Widget child;
  final VoidCallback onComplete;

  @override
  State<_FlyingItem> createState() => _FlyingItemState();
}

class _FlyingItemState extends State<_FlyingItem> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..forward().whenComplete(widget.onComplete);

    // Pop up slightly on pickup, hold near full size through the flight,
    // only shrink in the final stretch as it "lands".
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.4).chain(CurveTween(curve: Curves.easeInBack)),
        weight: 65,
      ),
    ]).animate(_c);

    // Stay fully opaque for most of the flight; only fade at the very end.
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Offset _arcPosition(double t) {
    final eased = Curves.easeInOutCubic.transform(t);
    // Control point is pulled well above the higher of the two points,
    // so the arc is clearly visible regardless of where on screen it flies.
    final topY = math.min(widget.start.dy, widget.end.dy);
    final control = Offset(
      (widget.start.dx + widget.end.dx) / 2,
      topY - 160,
    );
    final x = (1 - eased) * (1 - eased) * widget.start.dx +
        2 * (1 - eased) * eased * control.dx +
        eased * eased * widget.end.dx;
    final y = (1 - eased) * (1 - eased) * widget.start.dy +
        2 * (1 - eased) * eased * control.dy +
        eased * eased * widget.end.dy;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pos = _arcPosition(_c.value);
        final half = widget.size / 2;
        return Positioned(
          left: pos.dx - half,
          top: pos.dy - half,
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: ClipOval(child: widget.child),
              ),
            ),
          ),
        );
      },
    );
  }
}