import 'package:flutter/material.dart';

import 'core/api.dart';
import 'core/native_bridge.dart';
import 'screens/home_shell.dart';
import 'settings.dart';
import 'theme/app_theme.dart';

class XApp extends StatefulWidget {
  const XApp({super.key, required this.service, required this.settings});

  final XService service;
  final SettingsController settings;

  @override
  State<XApp> createState() => _XAppState();
}

class _XAppState extends State<XApp> {
  bool? _chromeDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'X',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: widget.settings.themeMode,
          builder: (context, child) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            if (_chromeDark != dark) {
              _chromeDark = dark;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                NativeBridge.syncChrome(dark);
              });
            }
            return child ?? const SizedBox.shrink();
          },
          home: HomeShell(service: widget.service, settings: widget.settings),
        );
      },
    );
  }
}
