import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemeMode { light, dark, special }

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.light);

  void toggleTheme(AppThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});
