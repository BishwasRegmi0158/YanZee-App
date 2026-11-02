import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_status_colors.dart';

class AppTheme {
  AppTheme._();

  // Radii (website: --radius 10px, xl = 14, 2xl = 18)
  static const double rLg = 10;
  static const double rXl = 14;
  static const double r2xl = 18;

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.brandRed600,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.red50,
      onPrimaryContainer: AppColors.red700,
      secondary: AppColors.zinc900,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.red50,
      onSecondaryContainer: AppColors.red700,
      surface: AppColors.white,
      onSurface: AppColors.zinc900,
      onSurfaceVariant: AppColors.zinc500,
      error: AppColors.red600,
      onError: AppColors.white,
      outline: AppColors.yzBorder,
      outlineVariant: AppColors.yzBorder,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.zinc50,
      surfaceContainer: AppColors.zinc100,
      surfaceContainerHigh: AppColors.zinc100,
      surfaceContainerHighest: AppColors.zinc100,
      inverseSurface: AppColors.zinc900,
      onInverseSurface: AppColors.white,
      scrim: AppColors.ink,
    );

    final base = ThemeData.light().textTheme.apply(
          fontFamily: AppFonts.body,
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    TextStyle heading(double size, FontWeight weight, {double ls = 0}) {
      return TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: ls,
        color: scheme.onSurface,
      );
    }

    final textTheme = base.copyWith(
      headlineLarge: heading(24, FontWeight.w700, ls: -0.4), // page title
      headlineMedium: heading(20, FontWeight.w700),
      headlineSmall: heading(18, FontWeight.w600), // section title
      titleLarge: heading(18, FontWeight.w600),
    );

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(rXl),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(rXl));
    const buttonText = TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    // 64 wide (not infinity) so buttons inside a Row never crash.
    const buttonSize = Size(64, 48);

    final primaryBg = WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.primary.withValues(alpha: 0.6);
      }
      if (states.contains(WidgetState.pressed) ||
          states.contains(WidgetState.hovered)) {
        return AppColors.brandRed700;
      }
      return scheme.primary;
    });

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.yzBg,
      extensions: const [AppStatusColors.light],
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.yzBg,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: heading(22, FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.zinc400, fontSize: 14),
        labelStyle: const TextStyle(
          color: AppColors.zinc600,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: TextStyle(color: AppColors.red700, fontSize: 12),
        prefixIconColor: AppColors.zinc400,
        suffixIconColor: AppColors.zinc400,
        border: border(scheme.outline),
        enabledBorder: border(scheme.outline),
        disabledBorder: border(scheme.outline),
        focusedBorder: border(scheme.primary, 1.5),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          disabledForegroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ).copyWith(backgroundColor: primaryBg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          disabledForegroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ).copyWith(backgroundColor: primaryBg),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.zinc700,
          backgroundColor: scheme.surfaceContainerLowest,
          side: BorderSide(color: scheme.outline),
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: buttonText,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 1,
        shadowColor: scheme.shadow.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r2xl),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r2xl),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        titleTextStyle: heading(18, FontWeight.w700),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(r2xl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rXl),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          color: scheme.onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.secondaryContainer,
        checkmarkColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: WidgetStateBorderSide.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : AppColors.zinc400,
            width: 1.5,
          );
        }),
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : AppColors.zinc400;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(scheme.onPrimary),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : AppColors.zinc200;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionHandleColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.2),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: scheme.onInverseSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}