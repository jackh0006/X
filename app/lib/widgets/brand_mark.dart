import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Vector brand mark shared by every platform.
///
/// Drawing the mark avoids image-decoder and asset-bundle differences between
/// Linux and Android while keeping the same orange squircle and white X as the
/// launcher icon.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'X',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: const _BrandPainter(),
      ),
    );
  }
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Rect.fromLTWH(0, 0, s, s);
    final squircle = RRect.fromRectAndRadius(
      rect,
      Radius.circular(s * 0.24),
    );
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDBA74), AppTheme.orange, Color(0xFFC2410C)],
      ).createShader(rect);
    canvas.drawRRect(squircle, background);

    final x = Paint()
      ..color = const Color(0xFFFFFDF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.155
      ..strokeCap = StrokeCap.round;
    final inset = s * 0.29;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(s - inset, s - inset),
      x,
    );
    canvas.drawLine(
      Offset(s - inset, inset),
      Offset(inset, s - inset),
      x,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandPainter oldDelegate) => false;
}
