import 'package:flutter/material.dart';

// Datadog brand purple palette
const ddPurple50  = Color(0xFFF5F0FB);
const ddPurple100 = Color(0xFFE8D9F7);
const ddPurple200 = Color(0xFFC9A8ED);
const ddPurple400 = Color(0xFF8B4ED9);
const ddPurple600 = Color(0xFF632CA6); // Datadog brand purple
const ddPurple700 = Color(0xFF4E2285);
const ddPurple800 = Color(0xFF3A1964);

final ThemeData dogPayTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ddPurple600,
    primary: ddPurple600,
    onPrimary: Colors.white,
    primaryContainer: ddPurple100,
    secondary: ddPurple400,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F5FC),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1A1A2E),
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Color(0xFF1A1A2E),
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0D6F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0D6F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ddPurple600, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: const TextStyle(color: Color(0xFF6B6B8A)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ddPurple600,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      elevation: 0,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFF0EAF8)),
    ),
  ),
);
