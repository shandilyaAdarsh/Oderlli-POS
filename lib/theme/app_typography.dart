import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

/// ─── Orderlyy POS · Typography System ───────────────────────────────────────
///
/// Responsive typography using locally bundled Inter font (variable font).
/// Font sizes are defined using ScreenUtil `.sp` units to ensure perfect scaling
/// on different tablet screen resolutions.
///
/// Inter is bundled as a variable font (assets/fonts/Inter-Variable.ttf),
/// supporting weights 100–900 without runtime network access.
abstract final class AppTypography {
  static const String _fontFamily = 'Inter';

  // ── Display Styles ────────────────────────────────────────────────────────
  static TextStyle get displayLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 48.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
      );

  static TextStyle get displayMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 36.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get displaySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 30.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ── Headline Styles ───────────────────────────────────────────────────────
  static TextStyle get headlineLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ── Title Styles ──────────────────────────────────────────────────────────
  static TextStyle get titleLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  // ── Body Styles ───────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ── Label Styles ──────────────────────────────────────────────────────────
  static TextStyle get labelLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textDisabled,
        letterSpacing: 0.5,
      );

  // ── POS-Specific Custom Styles ────────────────────────────────────────────
  static TextStyle get priceTag => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get priceLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get orderNumber => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      );

  static TextStyle get tableLabel => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get badgeText => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get buttonText => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get sidebarItem => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.sidebarText,
      );

  static TextStyle get sidebarItemActive => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.sidebarTextActive,
      );

  // ── Unified Semantic Text Styles ──────────────────────────────────────────

  /// Dashboard main view title style
  static TextStyle get dashboardTitle => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  /// Metrics text value style
  static TextStyle get metricValue => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  /// Metrics text label style
  static TextStyle get metricLabel => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Sidebar label in normal/inactive state
  static TextStyle get sidebarLabel => sidebarItem;

  /// Sidebar label in active state
  static TextStyle get sidebarLabelActive => sidebarItemActive;

  /// Subtitle styling for order and table cards
  static TextStyle get cardSubtitle => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ── TextTheme Generator ───────────────────────────────────────────────────
  /// Returns a full Material 3 TextTheme with locally bundled Inter.
  static TextTheme get textTheme => const TextTheme().copyWith(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
