import 'package:flutter/material.dart';

// Brand Colors (Derived from Logo)
const Color kNavy = Color(0xFF0F172A);
const Color kNavyLighter = Color(0xFF1E293B);
const Color kAccent = Color(0xFF00BAFF); // Electric Blue
const Color kCyan = Color(0xFF00D2FF);
const Color kBg = Color(0xFFF8FAFC);
const Color kSurface = Colors.white;

// Status Colors
const Color kSuccess = Color(0xFF10B981);
const Color kError = Color(0xFFEF4444);
const Color kWarning = Color(0xFFF59E0B);

// Gradients
const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [kAccent, kCyan],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
