import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/icon/icon.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
        semanticLabel: 'X',
      ),
    );
  }
}
