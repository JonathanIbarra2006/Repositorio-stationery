import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Este provider guardará el estado del tema actual (Claro u Oscuro)
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);