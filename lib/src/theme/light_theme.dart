import 'package:flutter/material.dart';
import 'package:sample/src/constants/string_constants.dart';
import 'package:sample/src/theme/light_text_theme.dart';
import 'package:sample/src/util/app_sizes.dart';

class LightTheme {
  LightTheme._();

  //   static Color get background => const Color(0xFFffffff);

  static Color get primaryBlueColor => const Color(0xFF0479F0);

  static Color get borderLightGreyColor => const Color(0xffabb0ba);

  static Color get textBlackColor => const Color(0xFF212121);

  static Color get textWhiteColor => const Color(0xFFFFFFFF);

  static Color get secondaryBlueColor => const Color(0xFF75BEFF);

  static Color get textGrayColor => const Color(0xFF717171);
  static Color get transparent => Colors.transparent;
  static Color get textDarkBlueColor => const Color(0xFF081B63);

  static Color get dividerColor => const Color(0xFF321C1C).withOpacity(0.13);

  static Color get textLightGrayColor => const Color(0xFFA0A0A0);
  static Color get lightBlueColor => const Color(0xFFEAF6FF);

  static ThemeData lightTheme = ThemeData(
    focusColor: primaryBlueColor,
    hintColor: textGrayColor,
    disabledColor: secondaryBlueColor,
    primaryColor: textBlackColor,
    secondaryHeaderColor: textLightGrayColor,
    fontFamily: StringConstants.fontFamily,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryBlueColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppWidgetSizes.dimen_6),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(width: 1.0, color: primaryBlueColor),
        backgroundColor: textWhiteColor,
        foregroundColor: textBlackColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppWidgetSizes.dimen_6),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryBlueColor,
      unselectedItemColor: textGrayColor,
      backgroundColor: textWhiteColor,
      selectedLabelStyle: LightTextTheme.lightTextTheme.titleMedium!.copyWith(
        color: textBlackColor,
      ),
      unselectedLabelStyle: LightTextTheme.lightTextTheme.titleMedium!.copyWith(
        color: textBlackColor,
      ),
    ),
    textTheme: LightTextTheme.lightTextTheme,
    textSelectionTheme: TextSelectionThemeData(
      selectionHandleColor: transparent,
    ),
  );
}
