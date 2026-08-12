import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _themeStorageKey = 'app_theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final value = await _storage.read(key: _themeStorageKey);
      if (value != null) {
        state = ThemeMode.values.firstWhere(
          (e) => e.toString() == value,
          orElse: () => ThemeMode.system, // Support system mode
        );
      } else {
        state = ThemeMode.system;
      }
    } catch (e) {
      state = ThemeMode.system;
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    try {
      await _storage.write(key: _themeStorageKey, value: newMode.toString());
    } catch (e) {
      // Ignored
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _themeStorageKey, value: mode.toString());
    } catch (e) {
      // Ignored
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
