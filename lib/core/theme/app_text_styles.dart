import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle splashDevanagari = TextStyle(
    fontFamily: AppFonts.devanagari,
    fontWeight: FontWeight.bold,
    fontSize: 32,
    color: AppColors.textGray,
  );

  static const TextStyle splashBrand = TextStyle(
    fontFamily: AppFonts.brand,
    fontWeight: FontWeight.bold,
    fontSize: 32,
    color: AppColors.textGray,
  );

  static const TextStyle loading = TextStyle(
    fontFamily: AppFonts.devanagari,
    fontSize: 10,
    letterSpacing: 6,
    color: AppColors.loadingGray,
  );
}
