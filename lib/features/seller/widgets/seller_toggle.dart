import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';

/// Animated on/off switch used across the seller pages.
///
/// ON:  coloured track, bright knob with a check.
/// OFF: track fades to grey, knob dims and the icon fades out ("powered down").
/// [loading] shows a spinner inside the knob while the server call runs.
/// Pass [onChanged] as null to disable it.
class SellerToggle extends StatelessWidget {
  const SellerToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.loading = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool loading;

  static const _duration = Duration(milliseconds: 320);
  static const _curve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onChanged == null;

    return AnimatedOpacity(
      duration: _duration,
      opacity: disabled ? 0.5 : 1,
      child: AnimatedToggleSwitch<bool>.dual(
        current: value,
        first: false,
        second: true,
        spacing: 20,
        height: 32,
        borderWidth: 3,
        indicatorSize: const Size.square(24),
        animationDuration: _duration,
        animationCurve: _curve,
        loading: loading,
        onChanged: disabled ? null : onChanged,
        style: const ToggleStyle(borderColor: Colors.transparent),
        styleBuilder: (on) => ToggleStyle(
          // OFF: grey, flat, dim knob. ON: coloured track, bright knob.
          backgroundColor: on ? scheme.primary : scheme.surfaceContainerHighest,
          indicatorColor: on ? scheme.onPrimary : scheme.outlineVariant,
        ),
        iconBuilder: (on) => AnimatedOpacity(
          duration: _duration,
          opacity: on ? 1 : 0,
          child: Icon(
            Icons.check_rounded,
            size: 14,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}