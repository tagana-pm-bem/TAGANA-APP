import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF6366F1);
  static const primaryForeground = Color(0xFFFFFFFF);

  // Base
  static const background = Color(0xFFFAFAFA);
  static const foreground = Color(0xFF0A0A0A);
  static const secondary = Color.fromARGB(255, 237, 237, 237);

  // Surface
  static const card = Color(0xFFFFFFFF);
  static const cardForeground = Color(0xFF0A0A0A);

  // Muted
  static const muted = Color(0xFFF4F4F5);
  static const mutedForeground = Color(0xFF71717A);

  // Borders & Inputs
  static const border = Color(0xFFE4E4E7);
  static const input = Color(0xFFE4E4E7);
  static const ring = Color(0xFF6366F1);

  // Semantic
  static const success = Color(0xFF16A34A);
  static const successForeground = Color(0xFFFFFFFF);

  static const warning = Color(0xFFCA8A04);
  static const warningForeground = Color(0xFFFFFFFF);

  static const destructive = Color(0xFFDC2626);
  static const destructiveForeground = Color(0xFFFFFFFF);

  static const navyLight = Color(0xFFe8eef7);
}
