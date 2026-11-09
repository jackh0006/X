import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const defaultExportName = 'X-encrypted-message.txt';

class StorageInfo {
  const StorageInfo({
    required this.dataPath,
    required this.cachePath,
    required this.preferencesPath,
    required this.exportFolder,
    required this.exportName,
  });

  final String dataPath;
  final String cachePath;
  final String preferencesPath;
  final String? exportFolder;
  final String exportName;
}

class SettingsController extends ChangeNotifier {
  SettingsController._(
    this._themeMode, [
    this._exportName = defaultExportName,
    this._exportFolder,
  ]);

  static const _channel = MethodChannel('com.jackh0006.x/native');

  ThemeMode _themeMode;
  String _exportName;
  String? _exportFolder;

  ThemeMode get themeMode => _themeMode;
  String get exportName => _exportName;
  String? get exportFolder => _exportFolder;

  String get themeLabel => switch (_themeMode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static String _storedTheme(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode _parseTheme(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String get _dataHome => Platform.environment['XDG_DATA_HOME'] ??
      '${Platform.environment['HOME'] ?? '.'}/.local/share';

  static String get _cacheHome => Platform.environment['XDG_CACHE_HOME'] ??
      '${Platform.environment['HOME'] ?? '.'}/.cache';

  static Directory get _linuxDir =>
      Directory('$_dataHome/com.jackh0006.x');

  static File get _linuxSettings => File('${_linuxDir.path}/settings.json');

  static File get _legacyThemeFile => File('${_linuxDir.path}/theme_mode');

  static Map<String, dynamic> _readLinuxSettings() {
    try {
      if (_linuxSettings.existsSync()) {
        final decoded = jsonDecode(_linuxSettings.readAsStringSync());
        if (decoded is Map<String, dynamic>) return decoded;
      }
      if (_legacyThemeFile.existsSync()) {
        return {'theme': _legacyThemeFile.readAsStringSync().trim()};
      }
    } catch (_) {
      // Fall through to defaults.
    }
    return const {};
  }

  static Future<SettingsController> load() async {
    if (Platform.isAndroid) {
      String? theme;
      String? name;
      String? folder;
      try {
        theme = await _channel.invokeMethod<String>('getTheme');
        name = await _channel.invokeMethod<String>('getExportName');
        folder = await _channel.invokeMethod<String>('getExportFolder');
      } catch (_) {
        // Defaults are safe.
      }
      return SettingsController._(
        _parseTheme(theme),
        _cleanName(name),
        folder?.isEmpty == true ? null : folder,
      );
    }

    final stored = _readLinuxSettings();
    final storedFolder = stored['export_folder'] as String?;
    return SettingsController._(
      _parseTheme(stored['theme'] as String?),
      _cleanName(stored['export_name'] as String?),
      storedFolder?.isEmpty == true ? null : storedFolder,
    );
  }

  factory SettingsController.inMemory([ThemeMode mode = ThemeMode.system]) =>
      SettingsController._(mode);

  static String _cleanName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty ||
        trimmed.contains('/') ||
        trimmed.contains('\\') ||
        trimmed == '.' ||
        trimmed == '..') {
      return defaultExportName;
    }
    return trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed;
  }

  Future<void> _persistLinux() async {
    await _linuxDir.create(recursive: true);
    await _linuxSettings.writeAsString(
      jsonEncode({
        'theme': _storedTheme(_themeMode),
        'export_name': _exportName,
        'export_folder': _exportFolder,
      }),
      flush: true,
    );
  }

  Future<void> _persist() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod<void>('setTheme', _storedTheme(_themeMode));
        await _channel.invokeMethod<void>('setExportName', _exportName);
        await _channel.invokeMethod<void>('setExportFolder', _exportFolder);
      } else if (Platform.isLinux) {
        await _persistLinux();
      }
    } catch (_) {
      // A preferences failure must never make the UI unusable.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> setExportName(String name) async {
    final cleaned = _cleanName(name);
    if (cleaned == _exportName) return;
    _exportName = cleaned;
    notifyListeners();
    await _persist();
  }

  Future<void> setExportFolder(String? folder) async {
    final value = (folder == null || folder.isEmpty) ? null : folder;
    if (value == _exportFolder) return;
    _exportFolder = value;
    notifyListeners();
    await _persist();
  }

  Future<String?> chooseExportFolder() async {
    try {
      if (Platform.isAndroid) {
        final folder = await _channel.invokeMethod<String>(
            'chooseExportFolder');
        if (folder == null || folder.isEmpty) return null;
        _exportFolder = folder;
        notifyListeners();
        return folder;
      }
      final folder = await getDirectoryPath(
        confirmButtonText: 'Use this folder',
      );
      if (folder == null) return null;
      await setExportFolder(folder);
      return folder;
    } catch (_) {
      return null;
    }
  }

  Future<StorageInfo> storageInfo() async {
    if (Platform.isAndroid) {
      try {
        final map = await _channel.invokeMapMethod<String, dynamic>(
            'getStorageInfo');
        if (map != null) {
          return StorageInfo(
            dataPath: map['data'] as String? ?? 'Unavailable',
            cachePath: map['cache'] as String? ?? 'Unavailable',
            preferencesPath: map['preferences'] as String? ?? 'Unavailable',
            exportFolder: map['exportFolder'] as String?,
            exportName: map['exportName'] as String? ?? _exportName,
          );
        }
      } catch (_) {
        // Fall through.
      }
    }
    if (Platform.isAndroid) {
      return StorageInfo(
        dataPath: 'Unavailable',
        cachePath: 'Unavailable',
        preferencesPath: 'Unavailable',
        exportFolder: _exportFolder,
        exportName: _exportName,
      );
    }
    return StorageInfo(
      dataPath: _linuxDir.path,
      cachePath: '$_cacheHome/com.jackh0006.x',
      preferencesPath: _linuxSettings.path,
      exportFolder: _exportFolder,
      exportName: _exportName,
    );
  }

  Future<void> deleteLocalData() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod<void>('deleteAppData');
      } else if (Platform.isLinux) {
        for (final directory in [
          _linuxDir,
          Directory('$_cacheHome/com.jackh0006.x'),
        ]) {
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
        }
      }
    } catch (_) {
      // Deletion is best effort and reported honestly by the caller.
    }
    _themeMode = ThemeMode.system;
    _exportName = defaultExportName;
    _exportFolder = null;
    notifyListeners();
  }
}
