// ═══════════════════════════════════════════════════════════════════════════
// lib/config/cantillana_theme.dart
// Tema personalizado basado en el escudo de Cantillana
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class CantillanaTheme {
  // ── Colores extraídos del escudo (tonos corporativos) ─────────────────────
  static const Color dorado = Color(0xFFD4AF37); // Dorado más suave
  static const Color doradoOscuro = Color(0xFFB8942A);
  static const Color rojo = Color(0xFFC62828); // Rojo más sobrio
  static const Color rojoOscuro = Color(0xFFB71C1C);
  static const Color verde = Color(0xFF2E7D32); // Verde corporativo
  static const Color verdeOscuro = Color(
    0xFF1B5E20,
  ); // Verde oscuro profesional
  static const Color azul = Color(0xFF1565C0); // Azul corporativo
  static const Color azulOscuro = Color(0xFF0D47A1);
  static const Color ocre = Color(0xFFE67E22); // Ocre suavizado
  static const Color ocreClaro = Color(0xFFF39C12);

  // ── Esquema de color principal (tonos corporativos) ───────────────────────
  static ColorScheme get colorScheme => ColorScheme(
    brightness: Brightness.light,
    primary: rojo,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE57373), // Rojo claro corporativo
    onPrimaryContainer: rojoOscuro,
    secondary: dorado,
    onSecondary: verdeOscuro,
    secondaryContainer: Color(0xFFE8D5A0), // Dorado claro suave
    onSecondaryContainer: doradoOscuro,
    tertiary: azul,
    onTertiary: Colors.white,
    tertiaryContainer: azulOscuro,
    onTertiaryContainer: Colors.white,
    error: rojoOscuro,
    onError: Colors.white,
    surface: Color(0xFF263238), // Verde oscuro grisáceo
    onSurface: Color(0xFFECEFF1), // Blanco suave
    surfaceContainerLowest: Color(0xFF1B2326),
    surfaceContainerHighest: Color(0xFF2E3A41),
    outline: Color(0xFFB8942A), // Dorado suave
    outlineVariant: Color(0xFF8D7422), // Dorado muy suave
  );

  // ── Esquema alternativo (dorado como primario) ────────────────────────────
  static ColorScheme get colorSchemeDorado => ColorScheme.fromSeed(
    seedColor: dorado,
    primary: dorado,
    onPrimary: verdeOscuro,
    primaryContainer: ocreClaro,
    onPrimaryContainer: Color(0xFFE65100),
    secondary: verde,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFA5D6A7),
    onSecondaryContainer: verdeOscuro,
    tertiary: azul,
    onTertiary: Colors.white,
    error: rojo,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF1C1B1F),
    surfaceContainerLowest: Color(0xFFFFF8E1),
    surfaceContainerHighest: Color(0xFFFFE0B2),
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    brightness: Brightness.light,
  );

  // ── Tema claro (Corporativo Cantillana) ───────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,

    // Fondo general de la app
    scaffoldBackgroundColor: Color(0xFF263238),

    // AppBar
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: rojo,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      shape: Border(
        bottom: BorderSide(color: dorado.withOpacity(0.4), width: 2),
      ),
    ),

    // Botones
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: rojo,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: dorado.withOpacity(0.5), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: dorado,
        side: BorderSide(color: dorado.withOpacity(0.6), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: rojo,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dorado.withOpacity(0.5), width: 1.5),
      ),
    ),

    // Tarjetas (con borde dorado sutil)
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dorado.withOpacity(0.3), width: 1.5),
      ),
      color: Color(0xFF2E3A41),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: Color(0xFF1B2326),
      selectedColor: rojo.withOpacity(0.9),
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFFECEFF1)),
      side: BorderSide(color: dorado.withOpacity(0.4), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF1B2326),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dorado.withOpacity(0.3), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dorado.withOpacity(0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dorado.withOpacity(0.7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: rojo.withOpacity(0.7), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: rojo, width: 1.5),
      ),
      labelStyle: TextStyle(color: Color(0xFFB0BEC5)),
      hintStyle: TextStyle(color: Color(0xFF78909C)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // Divisores
    dividerTheme: DividerThemeData(
      color: dorado.withOpacity(0.2),
      thickness: 1,
    ),

    // Tipografía
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFFECEFF1),
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFFECEFF1),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFECEFF1),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFECEFF1)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFFECEFF1),
      ),
    ),

    // Iconos
    iconTheme: IconThemeData(color: Color(0xFFD4AF37), size: 24),
  );

  // ── Tema claro (Dorado) ───────────────────────────────────────────────────
  static ThemeData get lightThemeDorado => ThemeData(
    useMaterial3: true,
    colorScheme: colorSchemeDorado,

    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: dorado,
      foregroundColor: verdeOscuro,
      iconTheme: IconThemeData(color: verdeOscuro),
      titleTextStyle: TextStyle(
        color: verdeOscuro,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: dorado,
        foregroundColor: verdeOscuro,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: verde,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Color(0xFFFFF3E0),
      selectedColor: dorado,
      labelStyle: const TextStyle(fontSize: 13),
      side: BorderSide(color: dorado.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFFFF8E1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dorado, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: rojo, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: rojo, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFFFFE0B2),
      thickness: 1,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1C1B1F),
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1C1B1F),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1C1B1F),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF49454F)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF49454F)),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2E7D32),
      ),
    ),

    iconTheme: IconThemeData(color: dorado, size: 24),
  );

  // ── Degradado del escudo ──────────────────────────────────────────────────
  static LinearGradient get escudoGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [rojo, verdeOscuro],
    stops: const [0.6, 0.6],
  );

  // ── Degradado para headers ────────────────────────────────────────────────
  static LinearGradient get headerGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rojo, rojoOscuro],
  );

  static LinearGradient get headerGradientDorado => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dorado, ocre],
  );
}
