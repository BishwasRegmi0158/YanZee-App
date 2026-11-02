import 'dart:ui';

/// Layer 1: the raw palette. Only files inside core/theme import this.
class AppColors {
  AppColors._();

  static const Color white = Color(0xFFFFFFFF);

  // Brand (website @theme)
  static const Color brandRed600 = Color(0xFFDC2020);
  static const Color brandRed700 = Color(0xFFB81A1A);

  // Surfaces
  static const Color yzBg = Color(0xFFF8F7F5);
  static const Color yzCard = Color(0xFFFFFFFF);
  static const Color yzBorder = Color(0xFFE2E0DB);
  static const Color yzMuted = Color(0xFF777777);

  // Neutrals (Tailwind zinc)
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc50 = Color(0xFFFAFAFA);

  // Feedback (Tailwind)
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green700 = Color(0xFF15803D);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange700 = Color(0xFFC2410C);

  // Splash and screens not migrated yet (existing names kept)
  static const Color background = Color(0xFF000000);
  static const Color homeBackground = yzBg;
  static const Color textGray = Color(0xFF8A8A8A);
  static const Color accentRed = brandRed600;
  static const Color loadingGray = Color(0xFFBFBFBF);
  static const Color gold = Color(0xFFB8894F);
  static const Color ink = Color(0xFF0D0D0F);
}