// lib/config/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application theme configuration
class AppTheme {
  AppTheme._();

  // ─── Brand Colors ────────────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF714B67);   // Odoo purple
  static const Color primaryLight = Color(0xFF8E6A86);
  static const Color primaryDark = Color(0xFF52364D);
  static const Color accentColor = Color(0xFF00A09D);    // Teal accent
  static const Color accentLight = Color(0xFF26C6C3);

  // ─── Status Colors ────────────────────────────────────────────────────────────
  static const Color successColor = Color(0xFF28A745);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFDC3545);
  static const Color infoColor = Color(0xFF17A2B8);

  // ─── Canvas & Editor Colors ──────────────────────────────────────────────────
  static const Color canvasBackground = Color(0xFFF8F9FA);
  static const Color dropZoneActive = Color(0xFFE8F5E9);
  static const Color dropZoneBorder = Color(0xFF4CAF50);
  static const Color fieldCardBackground = Color(0xFFFFFFFF);
  static const Color fieldCardBorder = Color(0xFFE0E0E0);
  static const Color groupBackground = Color(0xFFF5F0F4);
  static const Color groupBorder = Color(0xFFCBB5C6);
  static const Color selectedBorder = Color(0xFF714B67);
  static const Color draggingColor = Color(0xFF714B67);

  // ─── Panel Colors ────────────────────────────────────────────────────────────
  static const Color paletteBackground = Color(0xFF2D2D2D);
  static const Color paletteSurface = Color(0xFF3D3D3D);
  static const Color propertiesBackground = Color(0xFFFAFAFA);
  static const Color propertiesBorder = Color(0xFFEEEEEE);

  // ─── XML Highlight Colors ────────────────────────────────────────────────────
  static const Color xmlTagColor = Color(0xFF0000FF);
  static const Color xmlAttributeColor = Color(0xFF7D9029);
  static const Color xmlValueColor = Color(0xFFBA2121);
  static const Color xmlCommentColor = Color(0xFF408080);

  // ─── Light Theme ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: canvasBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: fieldCardBackground,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: fieldCardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 13,
        ),
        labelStyle: const TextStyle(fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: groupBackground,
        selectedColor: primaryColor.withOpacity(0.15),
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: const Color(0xFF16213E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2D2D2D)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
      ),
    );
  }

  // ─── Animation Durations ─────────────────────────────────────────────────
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // ─── Canvas ───────────────────────────────────────────────────────────────
  static const double canvasPadding = 24.0;

  // ─── Text Styles ─────────────────────────────────────────────────────────────
  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF616161),
        letterSpacing: 0.5,
      );

  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF757575),
      );

  static TextStyle get propertyValue => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF212121),
      );

  static TextStyle get xmlCode => GoogleFonts.firaCode(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF212121),
      );

  static TextStyle get fieldTypeBadge => GoogleFonts.firaCode(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );
}
