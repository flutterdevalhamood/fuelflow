import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  // Primary and accent colors
  primaryColor: Colors.blue.shade900,
  colorScheme: ColorScheme.light(
    primary: Colors.blue.shade900,
    secondary: Colors.blue.shade500,
  ),

  // AppBar theme
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue.shade900,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),

  // Text theme
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.blue.shade900,
    ),
    displayMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.blue.shade900,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),

  // Button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.blue.shade900,
    ),
  ),

  // Input decoration theme (for TextFormField)
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.blue.shade900),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.blue.shade900),
    ),
    labelStyle: TextStyle(color: Colors.blue.shade900),
    prefixIconColor: Colors.blue.shade900,
  ),

  // Card theme
  cardTheme: CardTheme(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
);
