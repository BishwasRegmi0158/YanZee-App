import 'package:flutter/material.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/theme/app_fonts.dart';

/// Compatibility shim. New screens should use Theme.of(context) instead.
class AuthColors {
  AuthColors._();
  static const pageBackground = AppColors.yzBg;
  static const screenBackground = AppColors.yzBg;
  static const cardBackground = Colors.white;
  static const textDark = AppColors.zinc900;
  static const tabsBackground = AppColors.zinc100;
  static const iconMuted = AppColors.zinc400;
  static const borderDefault = AppColors.yzBorder;
  static const borderFocused = AppColors.brandRed600;
  static const errorBackground = AppColors.red50;
  static const errorBorder = AppColors.red200;
  static const errorText = AppColors.red700;
  static const required = AppColors.red600;
  static const submitButton = AppColors.brandRed600;
  static const primary = AppColors.brandRed600;
  static const pillText = AppColors.zinc700;
  static const pillHint = AppColors.zinc500;
  static const pillIcon = AppColors.zinc500;
  static const subtitleGray = AppColors.zinc500;
}

class AuthTextStyles {
  AuthTextStyles._();

  static const heading = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 29,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.zinc900,
  );
  static const subheading = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 14,
    fontStyle: FontStyle.italic,
    color: AppColors.zinc500,
  );
  static const tab = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.zinc500);
  static const tabActive = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.zinc900);
  static const fieldLabel = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.zinc600);
  static const inputText = TextStyle(fontSize: 14, color: AppColors.zinc900);
  static const forgotLink = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandRed600);
  static const submitButton = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white);
  static const switchText = TextStyle(fontSize: 13, color: AppColors.zinc500);
  static const switchLink = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandRed600);
}

// The global theme already styles borders, fill and radius.
InputDecoration authInputDecoration({
  required String hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) =>
    InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );

// Pills are removed (the website has none). Same signature, so screens compile.
InputDecoration authPillInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) =>
    InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon,
    );

const List<BoxShadow> authPillShadow = [];