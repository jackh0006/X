import 'dart:async';

import 'package:flutter/services.dart';

/// Explicit copy with best-effort cleanup.
///
/// Clipboard clearing is not guaranteed by any OS. X clears only when the
/// current clipboard still contains the value it placed there.
Future<void> copySensitive(String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  Timer(const Duration(seconds: 60), () async {
    try {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (_) {
      // Android may restrict clipboard reads; fail quietly.
    }
  });
}
