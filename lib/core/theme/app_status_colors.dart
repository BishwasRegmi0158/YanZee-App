import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Layer 2 extras: roles that Material's ColorScheme has no slot for.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.successBg,
    required this.successFg,
    required this.dangerBg,
    required this.dangerFg,
    required this.infoBg,
    required this.infoFg,
    required this.warningBg,
    required this.warningFg,
    required this.neutralBg,
    required this.neutralFg,
    required this.errorBannerBg,
    required this.errorBannerBorder,
  });

  final Color successBg;
  final Color successFg;
  final Color dangerBg;
  final Color dangerFg;
  final Color infoBg;
  final Color infoFg;
  final Color warningBg;
  final Color warningFg;
  final Color neutralBg;
  final Color neutralFg;
  final Color errorBannerBg;
  final Color errorBannerBorder;

  static const light = AppStatusColors(
    successBg: AppColors.green100,
    successFg: AppColors.green700,
    dangerBg: AppColors.red100,
    dangerFg: AppColors.red700,
    infoBg: AppColors.blue100,
    infoFg: AppColors.blue700,
    warningBg: AppColors.orange100,
    warningFg: AppColors.orange700,
    neutralBg: AppColors.zinc100,
    neutralFg: AppColors.zinc600,
    errorBannerBg: AppColors.red50,
    errorBannerBorder: AppColors.red200,
  );

  @override
  AppStatusColors copyWith({
    Color? successBg,
    Color? successFg,
    Color? dangerBg,
    Color? dangerFg,
    Color? infoBg,
    Color? infoFg,
    Color? warningBg,
    Color? warningFg,
    Color? neutralBg,
    Color? neutralFg,
    Color? errorBannerBg,
    Color? errorBannerBorder,
  }) {
    return AppStatusColors(
      successBg: successBg ?? this.successBg,
      successFg: successFg ?? this.successFg,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerFg: dangerFg ?? this.dangerFg,
      infoBg: infoBg ?? this.infoBg,
      infoFg: infoFg ?? this.infoFg,
      warningBg: warningBg ?? this.warningBg,
      warningFg: warningFg ?? this.warningFg,
      neutralBg: neutralBg ?? this.neutralBg,
      neutralFg: neutralFg ?? this.neutralFg,
      errorBannerBg: errorBannerBg ?? this.errorBannerBg,
      errorBannerBorder: errorBannerBorder ?? this.errorBannerBorder,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppStatusColors(
      successBg: mix(successBg, other.successBg),
      successFg: mix(successFg, other.successFg),
      dangerBg: mix(dangerBg, other.dangerBg),
      dangerFg: mix(dangerFg, other.dangerFg),
      infoBg: mix(infoBg, other.infoBg),
      infoFg: mix(infoFg, other.infoFg),
      warningBg: mix(warningBg, other.warningBg),
      warningFg: mix(warningFg, other.warningFg),
      neutralBg: mix(neutralBg, other.neutralBg),
      neutralFg: mix(neutralFg, other.neutralFg),
      errorBannerBg: mix(errorBannerBg, other.errorBannerBg),
      errorBannerBorder: mix(errorBannerBorder, other.errorBannerBorder),
    );
  }
}

/// Short helpers so screens never write Theme.of(context) in long form.
extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppStatusColors get status => Theme.of(this).extension<AppStatusColors>()!;
}