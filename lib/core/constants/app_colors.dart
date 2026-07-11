// =============================================================================
// FILE: lib/core/constants/app_colors.dart
// =============================================================================
// PURPOSE: Centralized color definitions for the entire app
// WHY: Instead of scattering Color(0xFF...) everywhere, we define colors
//      in one place. Change a color here → it changes everywhere.
//      This is called the "Single Source of Truth" principle.
// BLOCS RELEVANCE: Colors are part of the UI layer. BLoC manages STATE,
//                  not colors. But a ThemeCubit could switch color schemes!
// =============================================================================

import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// AppColors — All app colors in one place
/// ═══════════════════════════════════════════════════════════════
///
/// Usage: AppColors.primary  →  Instead of Color(0xFF6C63FF)
///
/// This class has a private constructor so it can't be instantiated.
/// All members are static — access them directly via the class name.
///
class AppColors {
  // Private constructor prevents instantiation
  // WHY: This class is a namespace, not an object. You don't create
  // instances of it — you just use AppColors.primary, AppColors.error, etc.
  AppColors._();

  // ───────── Primary Colors ─────────
  // The main brand colors used throughout the app
  static const Color primary = Color(0xFF6C63FF); // Main purple
  static const Color primaryLight = Color(0xFF8B83FF); // Lighter variant
  static const Color primaryDark = Color(0xFF4A42CC); // Darker variant

  // ───────── Semantic Colors ─────────
  // Colors that convey meaning (success, error, warning, info)
  static const Color success = Color(0xFF4CAF50); // Green for done/success
  static const Color error = Color(0xFFEF5350); // Red for errors/delete
  static const Color warning = Color(0xFFFF9800); // Orange for warnings
  static const Color info = Color(0xFF2196F3); // Blue for information

  // ───────── Priority Colors ─────────
  // Different colors for different todo priority levels
  static const Color highPriority = Color(0xFFEF5350); // Red = urgent
  static const Color mediumPriority = Color(0xFFFF9800); // Orange = important
  static const Color lowPriority = Color(0xFF4CAF50); // Green = chill

  // ───────── Background Colors ─────────
  static const Color background = Color(0xFFF5F5F5); // Light mode bg
  static const Color surface = Color(0xFFFFFFFF); // Card/surface bg
  static const Color darkBackground = Color(0xFF121212); // Dark mode bg
  static const Color darkSurface = Color(0xFF1E1E1E); // Dark mode surface

  // ───────── Text Colors ─────────
  static const Color textPrimary = Color(0xFF212121); // Main text
  static const Color textSecondary = Color(0xFF757575); // Subtitle/hint text
  static const Color textDisabled = Color(0xFFBDBDBD); // Disabled text
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on primary

  // ───────── Utility Colors ─────────
  static const Color divider = Color(0xFFE0E0E0); // Divider lines
  static const Color shadow = Color(0x1A000000); // Subtle shadows
  static const Color overlay = Color(0x52000000); // Modal overlays
}
