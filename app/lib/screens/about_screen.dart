import 'package:flutter/material.dart';

import '../core/api.dart';
import '../data/donations.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/page_body.dart';
import '../widgets/section_heading.dart';
import '../widgets/surface_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.service});

  final XService service;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return PageBody(
      maxWidth: 820,
      children: [
        const SectionHeading(
          eyebrow: 'About',
          title: 'X',
          subtitle:
              'A small, offline-first utility for encrypting text before it travels through a channel you do not fully trust.',
        ),
        const VGap(22),
        SurfaceCard(
          accent: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(size: 68),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('X', style: text.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.1 · build 2',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _Pill('OFFLINE'),
                        _Pill('NO ACCOUNT'),
                        _Pill('OPEN SOURCE'),
                        _Pill('APACHE-2.0'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VGap(16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Developer', style: text.titleMedium),
              const VGap(8),
              SelectableText('jackh0006', style: text.bodyLarge),
              SelectableText(
                'jackh109867@gmail.com',
                style: text.bodyLarge?.copyWith(color: scheme.primary),
              ),
              const VGap(10),
              Text(
                'Made by jackh0006, with AI assistance.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const VGap(4),
              SelectableText(
                'github.com/jackh0006/X',
                style: text.bodyMedium?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ),
        const VGap(16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How it works', style: text.titleMedium),
              const VGap(12),
              const _Bullet(
                'Your message is encrypted on this device. X never contacts a server, creates an account, or uploads text.',
              ),
              const _Bullet(
                'XChaCha20-Poly1305 authenticates the ciphertext and the full header. A wrong passphrase or a modified message is rejected.',
              ),
              const _Bullet(
                'Argon2id turns the passphrase into the encryption key using a fresh 16-byte salt and 24-byte nonce for every encryption.',
              ),
              const _Bullet(
                'The output is portable text beginning with X1. You can send it through any messenger, email, or file transfer.',
              ),
              const _Bullet(
                'The passphrase is never embedded in the output. Share it separately and use a different channel when possible.',
              ),
              const VGap(10),
              Text(
                'Format v1 · XChaCha20-Poly1305-IETF · Argon2id v1.3 · X core ${service.coreVersion}',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const VGap(16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.handyman_outlined, color: scheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('Honest limits', style: text.titleMedium),
                ],
              ),
              const VGap(12),
              const _Bullet(
                'X is not a full messaging platform. It provides no forward secrecy, no sender identity, no metadata protection, and no deniability.',
              ),
              const _Bullet(
                'Only this build and the tested environments are claimed. No independent security audit has been performed.',
              ),
              const _Bullet(
                'Clipboard, screenshots, and a compromised operating system are outside X\'s control. Memory erasure cannot be guaranteed by Flutter, Dart, or the OS.',
              ),
              const _Bullet(
                'The ciphertext length reveals the approximate plaintext length. This is normal for standalone encryption.',
              ),
            ],
          ),
        ),
        const VGap(16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('License & source', style: text.titleMedium),
              const VGap(8),
              Text(
                'Apache License 2.0. The complete source, build instructions, tests, and security documentation are published in the GitHub repository.',
                style: text.bodyMedium,
              ),
              const VGap(8),
              SelectableText(
                'github.com/jackh0006/X',
                style: text.bodyMedium?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ),
        const VGap(20),
        Center(
          child: Text(
            'Encrypt privately. Share freely. Decrypt anywhere.',
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const VGap(8),
        Center(
          child: Text(
            'Donation addresses are published in the ${donationEntries.length} supported networks on the Donate screen.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.orange,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.55,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
