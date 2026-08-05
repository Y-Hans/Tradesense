import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemeMode {
  light,
  dark,
  special,
}

final themeModeProvider = StateProvider<AppThemeMode>((ref) => AppThemeMode.light);
