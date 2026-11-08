import 'dart:io';

import 'package:flutter/services.dart';

/// Android-only native actions (SAF save and share sheet).
///
/// Linux uses the platform file dialog directly; sharing is an Android feature.
class NativeBridge {
  static const _channel = MethodChannel('com.jackh0006.x/native');
  static const _themeChannel = MethodChannel('com.jackh0006.x/theme');

  static bool get supportsShare => Platform.isAndroid;

  static Future<bool> shareText(String text) async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('shareText', {'text': text}) ??
        false;
  }

  /// Keeps the GTK title bar in step with the in-app light/dark theme.
  static Future<void> syncChrome(bool dark) async {
    if (!Platform.isLinux) return;
    try {
      await _themeChannel.invokeMethod<void>('setDark', dark);
    } catch (_) {
      // A missing desktop channel must never break the app.
    }
  }

  static Future<bool> saveText(String text, {String filename = 'X-encrypted-message.txt'}) async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>(
          'saveText',
          {'text': text, 'filename': filename},
        ) ??
        false;
  }
}
