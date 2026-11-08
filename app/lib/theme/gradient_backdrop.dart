import 'package:flutter/material.dart';

import 'app_theme.dart';

class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = Theme.of(context).scaffoldBackgroundColor;
    return DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.95, -1.15),
                  radius: 1.35,
                  colors: [
                    AppTheme.orange.withValues(alpha: dark ? 0.12 : 0.065),
                    base.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.72],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.15, 1.2),
                  radius: 0.95,
                  colors: [
                    AppTheme.orange.withValues(alpha: dark ? 0.045 : 0.028),
                    base.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
