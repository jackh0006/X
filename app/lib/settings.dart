import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController._(this._preferences, this._themeMode);

  static const _themeKey = 'x.theme_mode';

  final SharedPreferences? _preferences;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  String get themeLabel => switch (_themeMode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static Future<SettingsController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_themeKey);
    final mode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return SettingsController._(preferences, mode);
  }

  factory SettingsController.inMemory([ThemeMode mode = ThemeMode.system]) =>
      SettingsController._(null, mode);

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _preferences?.setString(_themeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}
