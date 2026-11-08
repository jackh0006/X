import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/donations.dart';
import '../theme/app_theme.dart';
import '../widgets/info_banner.dart';
import '../widgets/page_body.dart';
import '../widgets/section_heading.dart';
import '../widgets/surface_card.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  static const _primary = [0, 1, 2, 3];

  @override
  Widget build(BuildContext context) {
    final more = donationEntries.sublist(4);
    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'Donate',
          title: 'Keep X free and independent.',
          subtitle:
              'X has no ads, no accounts, and no premium tier. Optional donations support maintenance of this and other open-source tools.',
        ),
        const VGap(22),
        for (final index in _primary) ...[
          _DonationCard(entry: donationEntries[index]),
          const VGap(12),
        ],
        Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            expansionTileTheme: ExpansionTileThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Theme.of(context).cardTheme.color,
              collapsedBackgroundColor: Theme.of(context).cardTheme.color,
              iconColor: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onSurface,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color!,
              ),
            ),
            child: ExpansionTile(
              title: Text(
                'More networks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'Dogecoin · XRP · TON · Litecoin',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              children: [
                for (final entry in more) ...[
                  _DonationCard(entry: entry),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        const VGap(10),
        const InfoBanner(
          icon: Icons.verified_outlined,
          tone: BannerTone.neutral,
          message:
              'These are public receiving addresses reproduced from jackh0006\'s published X-Wallet/DONATE.md. Verify the full address in two official locations before sending. Crypto transfers are irreversible.',
        ),
        const VGap(12),
        SelectableText(
          'Source: github.com/jackh0006/X-Wallet/blob/main/DONATE.md',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.entry});

  final DonationEntry entry;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: entry.address));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${entry.title} address copied.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  entry.symbol,
                  style: text.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.assets,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded, size: 19),
                tooltip: 'Copy ${entry.title} address',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: SelectableText(
              entry.address,
              style: text.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
