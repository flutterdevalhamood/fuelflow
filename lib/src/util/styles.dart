import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';

const quicksand = 'Quicksand';
const poppins = 'Poppins';
const montserrat = 'Montserrat';

TextTheme get textTheme => TextTheme(
  displayLarge: TextStyle(
    fontSize: 99,
    fontWeight: FontWeight.w300,
    color: Appcolors.text,
    fontFamily: quicksand,
  ),
  displayMedium: TextStyle(
    fontSize: 62,
    fontWeight: FontWeight.w300,
    color: Appcolors.text,
    fontFamily: quicksand,
  ),
  displaySmall: TextStyle(
    fontSize: 49,
    fontWeight: FontWeight.w400,
    fontFamily: quicksand,
    color: Appcolors.text,
  ),
  headlineMedium: TextStyle(
    fontSize: 35,
    fontWeight: FontWeight.w400,
    color: Appcolors.text,
    fontFamily: quicksand,
  ),
  headlineSmall: TextStyle(
    fontSize: AppWidgetSizes.fontSize24,
    fontWeight: FontWeight.w700,
    color: Appcolors.white,
    fontFamily: quicksand,
  ),
  titleLarge: TextStyle(
    fontSize: AppWidgetSizes.fontSize21,
    fontWeight: FontWeight.w500,
    fontFamily: quicksand,
    color: Appcolors.white,
  ),
  titleMedium: TextStyle(
    fontSize: AppWidgetSizes.fontSize16,
    fontWeight: FontWeight.w400,
    color: Appcolors.text,
    fontFamily: quicksand,
  ),
  titleSmall: TextStyle(
    fontSize: AppWidgetSizes.fontSize14,
    fontWeight: FontWeight.w700,
    color: Appcolors.white,
    fontFamily: quicksand,
  ),
  bodyLarge: TextStyle(
    fontSize: AppWidgetSizes.fontSize16,
    fontWeight: FontWeight.w400,
    color: Appcolors.white,
    fontFamily: quicksand,
  ),
  bodyMedium: TextStyle(
    fontSize: AppWidgetSizes.fontSize14,
    fontWeight: FontWeight.w400,
    color: Appcolors.text,
    fontFamily: quicksand,
  ),
  labelLarge: TextStyle(
    fontSize: AppWidgetSizes.fontSize16,
    fontWeight: FontWeight.w600,
    color: Appcolors.white,
    fontFamily: quicksand,
  ),
  bodySmall: TextStyle(
    fontSize: AppWidgetSizes.fontSize12,
    fontWeight: FontWeight.w400,
    color: Appcolors.text,
    fontFamily: quicksand,
  ),
  labelSmall: TextStyle(
    fontSize: AppWidgetSizes.fontSize10,
    fontWeight: FontWeight.w400,
    color: Appcolors.text,
    fontFamily: quicksand,
  ),
);

// To add custom text theme name
extension CustomStyles on TextTheme {
  TextStyle get buttonStyle {
    return const TextStyle(
      fontSize: 16,
      color: Appcolors.white,
      fontWeight: FontWeight.w700,
      fontFamily: quicksand,
    );
  }

  TextStyle get error {
    return TextStyle(
      fontSize: AppWidgetSizes.fontSize18,
      color: Colors.red,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle get success {
    return TextStyle(
      fontSize: AppWidgetSizes.fontSize18,
      color: Colors.green,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle get phoneInput {
    return TextStyle(
      fontSize: AppWidgetSizes.fontSize13,
      color: Appcolors.text,
      fontWeight: FontWeight.w500,
      fontFamily: quicksand,
    );
  }
}
