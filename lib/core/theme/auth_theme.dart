import 'package:flutter/material.dart';

class AuthColors {
  AuthColors._();

  static const pageBackground = Colors.white;
  static const cardBackground = Colors.white;
  static const textDark = Color(0xFF1A1A1A);

  static const tabsBackground = Color(0xFFF0EEEB);

  static const iconMuted = Color(0xFF9E9E9E);
  static const borderDefault = Color(0xFFE0DEDA);
  static const borderFocused = Color(0xFF1A1A1A);

  static const errorBackground = Color(0xFFFDECEC);
  static const errorBorder = Color(0xFFF5C2C2);
  static const errorText = Color(0xFFB3261E);

  static const required = Color(0xFFD32F2F);
  static const submitButton = Colors.black;
}

class AuthTextStyles {
  AuthTextStyles._();

  static const heading = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AuthColors.textDark,
  );

  static const subheading = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 15,
    fontStyle: FontStyle.italic,
    color: Color(0xFF6B6B6B),
  );

  static const tab = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF8A8A8A),
  );

  static const tabActive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AuthColors.textDark,
  );

  static const fieldLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AuthColors.textDark,
  );

  static const inputText = TextStyle(fontSize: 14, color: AuthColors.textDark);

  static const forgotLink = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF2F6FED),
  );

  static const submitButton = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const switchText = TextStyle(fontSize: 13, color: Color(0xFF6B6B6B));

  static const switchLink = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AuthColors.textDark,
  );
}

InputDecoration authInputDecoration({
  required String hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB0AEA9), fontSize: 14),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border(AuthColors.borderDefault),
    focusedBorder: border(AuthColors.borderFocused),
    errorBorder: border(AuthColors.errorBorder),
    disabledBorder: border(const Color(0xFFEDEBE7)),
    isDense: true,
  );
}

class AppFonts {
  AppFonts._();

  static const String devanagari = 'NotoSerifDevanagari';
  static const String brand = 'CormorantGaramond';
}