import 'package:flutter/material.dart';

class ThemeSettings {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  static void toggleTheme(ThemeMode mode) {
    themeMode.value = mode;
  }
}
