import 'package:flutter/material.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    required this.message,
    this.tone = BannerTone.neutral,
  });

  final IconData icon;
  final String message;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = switch (tone) {
      BannerTone.neutral => (
          scheme.surfaceContainerHighest.withValues(alpha: 0.7),
          scheme.onSurfaceVariant,
        ),
      BannerTone.brand => (
          scheme.primaryContainer.withValues(alpha: dark ? 0.35 : 0.55),
          dark ? scheme.onPrimaryContainer : scheme.onPrimaryContainer,
        ),
      BannerTone.error => (
          scheme.errorContainer.withValues(alpha: dark ? 0.35 : 0.5),
          dark ? scheme.onErrorContainer : scheme.onErrorContainer,
        ),
      BannerTone.success => (
          const Color(0xFF2E7D32).withValues(alpha: dark ? 0.24 : 0.10),
          dark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20),
        ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: fg,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum BannerTone { neutral, brand, error, success }
