import 'package:flutter/material.dart';

class LaptopServiceTheme {
  // Brand Color Palette untuk Servis Laptop
  static const Color techDarkBackground = Color(0xFF121824); // Latar belakang gelap futuristik
  static const Color techPrimary = Color(0xFF0F62FE);        // Biru siber presisi
  static const Color repairAccent = Color(0xFFFF9900);       // Amber/Oranye mekanik/servis
  static const Color surfaceLight = Color(0xFFF4F6F9);       // Latar terang bersih
  static const Color surfaceDark = Color(0xFF1E2640);        // Card gelap

  // 1. TEMA TERANG (Light Mode)
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: techPrimary,
      scaffoldBackgroundColor: surfaceLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: techDarkBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: techPrimary),
      ),
      colorScheme: const ColorScheme.light(
        primary: techPrimary,
        secondary: repairAccent,
        surface: Colors.white,
      ),
      // Styling Button Utama
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: repairAccent, // Tombol aksi utama berwarna oranye servis
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      // Styling Input Field Form
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: techPrimary, width: 2),
        ),
      ),
    );
  }

  // 2. TEMA GELAP (Dark Mode)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: techPrimary,
      scaffoldBackgroundColor: techDarkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: techPrimary,
        secondary: repairAccent,
        surface: surfaceDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: repairAccent,
          foregroundColor: techDarkBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: repairAccent, width: 2),
        ),
      ),
    );
  }
}