import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsController extends ChangeNotifier {
  SettingsController._(this._themeMode);

  static const _channel = MethodChannel('com.jackh0006.x/native');

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  String get themeLabel => switch (_themeMode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static String _storedValue(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode _parse(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static File get _linuxFile {
    final dataHome = Platform.environment['XDG_DATA_HOME'] ??
        '${Platform.environment['HOME'] ?? '.'}/.local/share';
    return File('$dataHome/com.jackh0006.x/theme_mode');
  }

  static Future<SettingsController> load() async {
    String? stored;
    if (Platform.isAndroid) {
      try {
        stored = await _channel.invokeMethod<String>('getTheme');
      } catch (_) {
        stored = null;
      }
    } else if (Platform.isLinux) {
      try {
        final file = _linuxFile;
        if (await file.exists()) stored = (await file.readAsString()).trim();
      } catch (_) {
        stored = null;
      }
    }
    return SettingsController._(_parse(stored));
  }

  factory SettingsController.inMemory([ThemeMode mode = ThemeMode.system]) =>
      SettingsController._(mode);

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final value = _storedValue(mode);
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod<void>('setTheme', value);
      } else if (Platform.isLinux) {
        final file = _linuxFile;
        await file.parent.create(recursive: true);
        await file.writeAsString(value, flush: true);
      }
    } catch (_) {
      // A preferences failure must never make the UI unusable.
    }
  }
}
