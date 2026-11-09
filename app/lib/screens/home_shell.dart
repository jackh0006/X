import 'package:flutter/material.dart';

import '../core/api.dart';
import '../settings.dart';
import '../theme/gradient_backdrop.dart';
import '../widgets/brand_mark.dart';
import 'about_screen.dart';
import 'donate_screen.dart';
import 'receive_screen.dart';
import 'send_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.service, required this.settings});

  final XService service;
  final SettingsController settings;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = <_Destination>[
    _Destination('SEND', Icons.north_east_rounded, Icons.send_rounded),
    _Destination('RECEIVE', Icons.south_west_rounded, Icons.move_to_inbox_rounded),
    _Destination('DONATE', Icons.favorite_outline_rounded, Icons.favorite_rounded),
    _Destination('ABOUT', Icons.info_outline_rounded, Icons.info_rounded),
  ];

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    final pages = <Widget>[
      SendScreen(service: widget.service, settings: widget.settings),
      ReceiveScreen(service: widget.service),
      const DonateScreen(),
      AboutScreen(service: widget.service, settings: widget.settings),
    ];

    return GradientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 74,
          titleSpacing: 20,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 38),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'X',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            letterSpacing: 2.8,
                            height: 1.0,
                          ),
                    ),
                    if (MediaQuery.textScalerOf(context).scale(1) < 1.35)
                      Text(
                        'ENCRYPTED TEXT, ANYWHERE',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  letterSpacing: 1.55,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            _ThemeButton(settings: widget.settings),
            const SizedBox(width: 8),
          ],
        ),
        body: desktop
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -0.7,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).dividerTheme.color,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _index,
                      children: pages,
                    ),
                  ),
                ],
              )
            : IndexedStack(
                index: _index,
                children: pages,
              ),
        bottomNavigationBar: desktop
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerTheme.color ?? Colors.transparent,
                    ),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final d in _destinations)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: d.label,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final icon = switch (settings.themeMode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme: ${settings.themeLabel}',
      icon: Icon(icon, size: 21),
      initialValue: settings.themeMode,
      onSelected: settings.setThemeMode,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ThemeMode.system,
          child: _ThemeItem(Icons.brightness_auto_rounded, 'System'),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: _ThemeItem(Icons.light_mode_rounded, 'Light'),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: _ThemeItem(Icons.dark_mode_rounded, 'Dark'),
        ),
      ],
    );
  }
}

class _ThemeItem extends StatelessWidget {
  const _ThemeItem(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
