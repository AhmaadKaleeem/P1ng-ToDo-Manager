import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF5F1EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFAF7F2);
  static const Color textPrimary = Color(0xFF1A1D24);
  static const Color textSecondary = Color(0xFF78716C);
  static const Color action = Color(0xFF0EA5E9);
  static const Color attention = Color(0xFFF59E0B);
  static const Color alert = Color(0xFFEF4444);
  static const Color divider = Color(0xFFE8E3DA);
  static const Color decorPink = Color(0xFFF472B6);
  static const Color decorCoral = Color(0xFFFB7185);
  static const Color decorNavy = Color(0xFF1E3A8A);

  static Color textSecondaryOpacity(double opacity) => textSecondary.withValues(alpha: opacity);
}
