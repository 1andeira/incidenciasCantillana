// ─────────────────────────────────────────
// lib/config/cantillana_theme.dart
// Paleta corporativa de Cantillana
// ─────────────────────────────────────────

import 'package:flutter/material.dart';

abstract final class CantillanaTheme {
  // ── Colores principales ────────────────
  static const Color rojo = Color(0xFFC0392B); // rojo municipal
  static const Color rojoOscuro = Color(0xFF922B21); // hover / gradiente
  static const Color dorado = Color(0xFFF1C40F); // acento dorado
  static const Color verdeOscuro = Color(0xFF145A32); // fondo principal

  // ── Colores de estado (incidencias) ───
  static const Color estadoPendiente = Color(0xFFFF9800); // orange
  static const Color estadoEnProceso = Color(0xFF2196F3); // blue
  static const Color estadoResuelta = Color(0xFF4CAF50); // green
  static const Color estadoRechazada = rojo;

  // ── ThemeData completo ─────────────────
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: rojo,
      brightness: Brightness.dark,
      primary: rojo,
      secondary: dorado,
      surface: verdeOscuro,
    ),
    scaffoldBackgroundColor: verdeOscuro,
    appBarTheme: const AppBarTheme(
      backgroundColor: rojo,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: rojo,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Color(0xFF1B5E20),
      selectedColor: rojo,
      labelStyle: const TextStyle(color: Colors.white),
      side: BorderSide(color: dorado, width: 1.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1B5E20),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: dorado, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: dorado, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: dorado, width: 3),
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF1B5E20),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: verdeOscuro,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(color: Colors.white70),
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: verdeOscuro),
  );
}
