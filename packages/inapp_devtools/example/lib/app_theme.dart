import 'package:flutter/material.dart';

/// Postman-inspired dark palette shared across the example app.
abstract final class ExampleTheme {
  static const background = Color(0xFF1E1E1E);
  static const surface = Color(0xFF2D2D2D);
  static const primary = Color(0xFFFF6C37);
  static const onSurface = Color(0xFFE0E0E0);
  static const muted = Color(0xFF9E9E9E);
  static const border = Color(0xFF404040);
  static const success = Color(0xFF4CAF50);

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        outline: border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: primary,
        textColor: onSurface,
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: onSurface, fontSize: 14),
        bodySmall: TextStyle(color: muted, fontSize: 12),
        labelLarge: TextStyle(
          color: onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
