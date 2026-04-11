import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Theme layout measurements
  static const double radiusCard = 20.0;
  static const double radiusButton = 14.0;

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bloomCream,
        colorScheme: const ColorScheme.light(
          primary: AppColors.bloomRose,
          secondary: AppColors.bloomSky,
          surface: AppColors.bloomCream,
          error: AppColors.bloomDestructive,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.bloomInk,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
          displayLarge: GoogleFonts.playfairDisplay(color: AppColors.bloomInk, fontWeight: FontWeight.w700),
          displayMedium: GoogleFonts.playfairDisplay(color: AppColors.bloomInk, fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.dmSerifDisplay(color: AppColors.bloomInk),
          headlineMedium: GoogleFonts.dmSerifDisplay(color: AppColors.bloomInk),
          titleLarge: GoogleFonts.plusJakartaSans(color: AppColors.bloomInk, fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.plusJakartaSans(color: AppColors.bloomBody),
          bodyMedium: GoogleFonts.plusJakartaSans(color: AppColors.bloomBody),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bloomCream.withOpacity(0.4),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.bloomRose),
          titleTextStyle: GoogleFonts.dmSerifDisplay(
            color: AppColors.bloomInk,
            fontSize: 20,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bloomRose,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
            side: const BorderSide(color: Color(0x1A2E8B72)), // AppColors.bloomRose.withOpacity(0.1)
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: Color(0x332E8B72)), // AppColors.bloomRose.withOpacity(0.2)
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: Color(0x1A2E8B72)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: AppColors.bloomRose, width: 2),
          ),
          hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.bloomMauve),
          labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.bloomMauve),
          contentPadding: const EdgeInsets.all(16),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white.withOpacity(0.4),
          elevation: 0,
          selectedItemColor: AppColors.bloomRose,
          unselectedItemColor: AppColors.bloomInk.withOpacity(0.6),
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
          type: BottomNavigationBarType.fixed,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.bloomRose,
          secondary: AppColors.bloomSky,
          surface: AppColors.darkCard,
          error: AppColors.bloomDestructive,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.darkInk,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
          displayLarge: GoogleFonts.playfairDisplay(color: AppColors.darkInk, fontWeight: FontWeight.w700),
          displayMedium: GoogleFonts.playfairDisplay(color: AppColors.darkInk, fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.dmSerifDisplay(color: AppColors.darkInk),
          headlineMedium: GoogleFonts.dmSerifDisplay(color: AppColors.darkInk),
          titleLarge: GoogleFonts.plusJakartaSans(color: AppColors.darkInk, fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.plusJakartaSans(color: AppColors.darkSecondary),
          bodyMedium: GoogleFonts.plusJakartaSans(color: AppColors.darkSecondary),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkCard.withOpacity(0.4),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.bloomRose),
          titleTextStyle: GoogleFonts.dmSerifDisplay(
            color: AppColors.darkInk,
            fontSize: 20,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bloomRose,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
            side: const BorderSide(color: Color(0x0DFFFFFF)), // white with 5% opacity
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: AppColors.bloomRose, width: 2),
          ),
          hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.darkMauve),
          labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.darkMauve),
          contentPadding: const EdgeInsets.all(16),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface.withOpacity(0.4),
          elevation: 0,
          selectedItemColor: AppColors.bloomRose,
          unselectedItemColor: AppColors.darkMauve.withOpacity(0.6),
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
          type: BottomNavigationBarType.fixed,
        ),
      );
}
