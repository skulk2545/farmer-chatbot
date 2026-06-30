import 'package:flutter/material.dart';

class AppStyles {
  // Padding & Margin Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Border Radius Constants
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 28.0;

  // Box Shadows for elevation effects
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
        blurRadius: 10,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      )
    ];
  }

  // Common Border outline style
  static OutlineInputBorder inputBorder(Color color, {double width = 1.0, double radius = radiusSmall}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
