import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de Cores
  static const Color _primaryGreen = Color(0xFF00E676); // Verde Neon vibrante
  static const Color _backgroundBlack = Color(0xFF121212); // Preto profundo
  static const Color _surfaceBlack = Color(0xFF1E1E1E); // Preto um pouco mais claro para cards
  static const Color _textWhite = Color(0xFFFFFFFF);
  static const Color _textGrey = Color(0xFFB3B3B3);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: _primaryGreen,
      scaffoldBackgroundColor: _backgroundBlack,
      
      colorScheme: const ColorScheme.dark(
        primary: _primaryGreen,
        secondary: _primaryGreen,
        background: _backgroundBlack,
        surface: _surfaceBlack,
        onPrimary: _backgroundBlack, // Texto em cima do verde deve ser preto
        onSurface: _textWhite,
      ),

      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineMedium: const TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        bodyLarge: const TextStyle(color: _textWhite),
        bodyMedium: const TextStyle(color: _textGrey),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _backgroundBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: _primaryGreen, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: _primaryGreen),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: _backgroundBlack, // Texto do botão
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
       
      // Estilo para campos de texto (Login)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: _textGrey),
        prefixIconColor: _textGrey,
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceBlack,
        selectedItemColor: _primaryGreen,
        unselectedItemColor: _textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      )
    );
  }
}