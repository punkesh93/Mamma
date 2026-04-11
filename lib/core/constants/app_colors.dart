import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color bloomRose = Color(0xFF2E8B72); // deep teal-green
  static const Color bloomSky = Color(0xFF2A7A90); // deep teal-blue
  static const Color bloomLavender = Color(0xFF6B4B9A); // deep purple
  static const Color bloomSage = Color(0xFF4A8C3A); // deep forest green
  static const Color bloomWarning = Color(0xFFB8760A); // dark amber
  static const Color bloomSuccess = Color(0xFF2E8B72);
  static const Color bloomDestructive = Color(0xFFB03030);

  static const Color bloomCream = Color(0xFFFAFAFA); // page background
  static const Color bloomBlush = Color(0xFFFFF0F5); // card tint

  static const Color bloomInk = Color(0xFF1A1A1A);
  static const Color bloomBody = Color(0xFF2D2D2D);
  static const Color bloomMauve = Color(0xFF5C5470);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2A2A2A);
  static const Color darkInk = Color(0xFFFFFFFF);
  static const Color darkSecondary = Color(0xFFE5E5E5);
  static const Color darkMauve = Color(0xFFB0A8C0);
  static const Color darkMint = Color(0xFF5BDBA0);
  static const Color darkPink = Color(0xFFF06292);

  // Helper gradients
  static const LinearGradient insightGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA8E6CF),
      Color(0xFFD7BDE2),
      Color(0xFFA8DADC),
      Color(0xFFF8C8DC)
    ],
  );

  static const LinearGradient insightGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E7D5A),
      Color(0xFF5C4A7A),
      Color(0xFF2A5A7A),
      Color(0xFF7A3050)
    ],
  );
}
