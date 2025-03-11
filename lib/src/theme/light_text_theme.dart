import 'package:flutter/material.dart';
import 'package:sample/src/theme/light_theme.dart';
import 'package:sample/src/util/app_sizes.dart';

class LightTextTheme {
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: AppWidgetSizes.fontSize24,
      fontWeight: FontWeight.w700,
      color: LightTheme.textBlackColor,
    ),
    displayMedium: TextStyle(
      fontSize: AppWidgetSizes.fontSize20,
      fontWeight: FontWeight.w600,
      color: LightTheme.textBlackColor,
    ),
    displaySmall: TextStyle(
      fontSize: AppWidgetSizes.fontSize18,
      fontWeight: FontWeight.w700,
      color: LightTheme.textBlackColor,
    ),
    headlineLarge: TextStyle(
      fontSize: AppWidgetSizes.fontSize16,
      fontWeight: FontWeight.w700,
      color: LightTheme.textBlackColor,
    ),
    headlineMedium: TextStyle(
      fontSize: AppWidgetSizes.fontSize16,
      fontWeight: FontWeight.w800,
      color: LightTheme.textDarkBlueColor,
    ),
    headlineSmall: TextStyle(
      fontSize: AppWidgetSizes.fontSize13,
      fontWeight: FontWeight.w400,
      color: LightTheme.textBlackColor,
    ),
    bodyLarge: TextStyle(
      fontSize: AppWidgetSizes.fontSize14,
      fontWeight: FontWeight.w700,
      color: LightTheme.textBlackColor,
    ),
    bodyMedium: TextStyle(
      fontSize: AppWidgetSizes.fontSize14,
      fontWeight: FontWeight.w500,
      color: LightTheme.textBlackColor,
    ),
    bodySmall: TextStyle(
      fontSize: AppWidgetSizes.fontSize14,
      fontWeight: FontWeight.w400,
      color: LightTheme.textBlackColor,
    ),
    labelLarge: TextStyle(
      fontSize: AppWidgetSizes.fontSize12,
      fontWeight: FontWeight.w700,
      color: LightTheme.textBlackColor,
    ),
    labelMedium: TextStyle(
      fontSize: AppWidgetSizes.fontSize12,
      fontWeight: FontWeight.w500,
      color: LightTheme.textBlackColor,
    ),
    labelSmall: TextStyle(
      fontSize: AppWidgetSizes.fontSize12,
      fontWeight: FontWeight.w400,
      color: LightTheme.textGrayColor,
    ),
    titleSmall: TextStyle(
      fontSize: AppWidgetSizes.fontSize11,
      fontWeight: FontWeight.w400,
      color: LightTheme.textBlackColor,
    ),
    titleMedium: TextStyle(
      fontSize: AppWidgetSizes.fontSize11,
      fontWeight: FontWeight.w500,
      color: LightTheme.textBlackColor,
    ),
    titleLarge: TextStyle(
      fontSize: AppWidgetSizes.fontSize11,
      fontWeight: FontWeight.w700,
      color: LightTheme.textBlackColor,
    ),
  );
}
