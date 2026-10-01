import 'package:flutter/material.dart';

/// Centralized Design System for DeFort Security App
class AppColors {
  // Primary
  static const Color primary = Color(0xFF4F46E5); // Indigo-600
  static const Color primaryLight = Color(0xFF818CF8); // Indigo-400
  static const Color primaryDark = Color(0xFF3730A3); // Indigo-800

  // Backgrounds
  static const Color bgLight = Color(0xFFF3F4F6); // Gray-100
  static const Color bgDark = Color(0xFF111827); // Gray-900
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937); // Gray-800

  // Text
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Feature Colors
  static const Color scanColor = Color(0xFF6366F1);
  static const Color phishingColor = Color(0xFFF97316);
  static const Color networkColor = Color(0xFF14B8A6);
  static const Color premiumColor = Color(0xFFFBBF24);

  // Glass Effect
  static Color glassLight = Colors.white.withOpacity(0.6);
  static Color glassDark = Colors.black.withOpacity(0.3);
  static Color glassBorderLight = Colors.white.withOpacity(0.8);
  static Color glassBorderDark = Colors.white24;

  // Blobs
  static const Color blobBlue = Color(0xFF93C5FD);
  static const Color blobPurple = Color(0xFFC4B5FD);
  static const Color blobGreen = Color(0xFFA7F3D0);
  static const Color blobRed = Color(0xFFFCA5A5);
  static const Color blobOrange = Color(0xFFFDBA74);
  static const Color blobIndigo = Color(0xFF818CF8);
  static const Color blobTeal = Color(0xFF34D399);
  static const Color blobYellow = Color(0xFFFDE047);
  static const Color blobEmerald = Color(0xFF6EE7B7);

  // Helpers
  static Color bg(bool isDark) => isDark ? bgDark : bgLight;
  static Color surface(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color textPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimaryLight;
  static Color textSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondaryLight;
  static Color glass(bool isDark) => isDark ? glassDark : glassLight;
  static Color glassBorder(bool isDark) => isDark ? glassBorderDark : glassBorderLight;
  static Color primaryAdaptive(bool isDark) => isDark ? primaryLight : primary;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 32;
}
