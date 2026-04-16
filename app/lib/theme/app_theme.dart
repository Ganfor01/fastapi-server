import 'package:flutter/material.dart';

class AppTheme {
  static const Color colorPrincipal = Color(0xFF5B7CFA);
  static const Color colorFondo = Color(0xFFF5F7FB);
  static const Color colorSuperficie = Color(0xFFFFFFFF);

  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorPrincipal,
        primary: colorPrincipal,
        surface: colorSuperficie,
      ),
      scaffoldBackgroundColor: colorFondo,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorSuperficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFE7EBF3)),
        ),
      ),
    );
  }

  const AppTheme._();
}
