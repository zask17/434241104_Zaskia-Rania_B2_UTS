import 'package:flutter/material.dart';

class ThemeSettings {
  // Notifier untuk memantau perubahan tema (Light/Dark/System)
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  // Notifier untuk menyimpan preferensi On/Off switch notifikasi status laptop
  static final ValueNotifier<bool> isLaptopNotificationEnabled = ValueNotifier<bool>(true);

  static void toggleTheme(ThemeMode mode) {
    themeMode.value = mode;
  }

  static void setLaptopNotification(bool value) {
    isLaptopNotificationEnabled.value = value;
  }
}