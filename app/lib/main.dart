import 'package:flutter/material.dart';

import 'app.dart';
import 'core/native_x_service.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsController.load();
  runApp(XApp(service: const NativeXService(), settings: settings));
}
