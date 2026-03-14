import 'package:flutter/material.dart';

class AppTheme {

  /// DARK THEME
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    scaffoldBackgroundColor: const Color(0xFF0F1117),

    primaryColor: const Color(0xFF7B61FF),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7B61FF),
      secondary: Color(0xFF00D4FF),
    ),
  );

  /// LIGHT THEME
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,

    scaffoldBackgroundColor: const Color(0xFFF5F6FA),

    primaryColor: const Color(0xFF7B61FF),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF7B61FF),
      secondary: Color(0xFF00D4FF),
    ),
  );

}