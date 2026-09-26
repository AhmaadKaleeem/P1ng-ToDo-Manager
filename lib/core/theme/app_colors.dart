import 'package:flutter/material.dart';

/// Midnight Navy / Dark Slate / Ash / Terminal Green / Warning Amber
abstract final class AppColors {
  static const background = Color(0xFF0B1120);
  static const surface = Color(0xFF111827);
  static const textPrimary = Color(0xFFF3F4F6);
  static const action = Color(0xFF10B981);
  static const alert = Color(0xFFF59E0B);

  static Color textSecondary([double opacity = 0.62]) =>
      textPrimary.withValues(alpha: opacity);

  static const divider = Color(0xFF1F2937);
  static const surfaceElevated = Color(0xFF1A2332);
}
