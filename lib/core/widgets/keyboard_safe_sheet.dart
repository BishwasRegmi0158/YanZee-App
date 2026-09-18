import 'package:flutter/material.dart';

/// Displays a bottom sheet that safely animates directly above the soft keyboard.
Future<T?> showKeyboardSafeSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxHeightFraction = 0.85,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true, // Forces reading viewInsets from the root window
    useSafeArea: true,
    backgroundColor: Colors.transparent, // Eliminates background box artifacts
    elevation: 0,
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      final screenHeight = MediaQuery.of(ctx).size.height;

      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: const Duration(milliseconds: 150),
        curve: Curves.decelerate,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * maxHeightFraction,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: builder(ctx),
              ),
            ),
          ),
        ),
      );
    },
  );
}