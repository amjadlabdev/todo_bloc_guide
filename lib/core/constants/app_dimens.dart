// =============================================================================
// FILE: lib/core/constants/app_dimens.dart
// =============================================================================
// PURPOSE: All spacing, sizing, and dimension constants
// WHY: Consistent spacing = professional look. Instead of random SizedBox
//      heights (8, 10, 12, 16...), we use predefined sizes for consistency.
// =============================================================================

class AppDimens {
  AppDimens._();

  // ───────── Spacing ─────────
  // Based on 4px grid system (standard in Material Design)
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;
  static const double spacing80 = 80.0;

  // ───────── Border Radius ─────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusCircular = 100.0; // For fully rounded elements

  // ───────── Icon Sizes ─────────
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  // ───────── Card ─────────
  static const double cardElevation = 2.0;
  static const double cardPadding = 16.0;

  // ───────── Button ─────────
  static const double buttonHeight = 48.0;
  static const double buttonBorderRadius = 12.0;

  // ───────── Text Field ─────────
  static const double textFieldBorderRadius = 12.0;
}
