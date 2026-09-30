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


static const screenBackground = Color(0xFFF7F8FA);
static const primary = Color(0xFF3BB77E); // green button / links
static const pillText = Color(0xFF2E3134);
static const pillHint = Color(0xFF5F6368);
static const pillIcon = Color(0xFF55595C);
static const subtitleGray = Color(0xFF6B7075);
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

/// Wrap the TextField in a Container with [authPillShadow] for the soft shadow.
InputDecoration authPillInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AuthColors.pillHint, fontSize: 14),
    prefixIcon: Icon(icon, size: 20, color: AuthColors.pillIcon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: border(Colors.transparent, 0),
    enabledBorder: border(Colors.transparent, 0),
    focusedBorder: border(AuthColors.primary, 1.2),
    errorBorder: border(AuthColors.errorBorder, 1),
    disabledBorder: border(Colors.transparent, 0),
  );
}

const authPillShadow = [
  BoxShadow(
    color: Color(0x12000000),
    blurRadius: 14,
    offset: Offset(0, 4),
  ),
];