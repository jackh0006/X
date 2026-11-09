import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/native_bridge.dart';
import '../theme/app_theme.dart';
import 'info_banner.dart';
import 'surface_card.dart';

Future<void> showPhraseQrDialog(BuildContext context, String phrase) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PhraseQrDialog(phrase: phrase),
  );
}

class PhraseQrDialog extends StatefulWidget {
  const PhraseQrDialog({super.key, required this.phrase});

  final String phrase;

  @override
  State<PhraseQrDialog> createState() => _PhraseQrDialogState();
}

class _PhraseQrDialogState extends State<PhraseQrDialog> {
  @override
  void initState() {
    super.initState();
    NativeBridge.setSecureScreen(true);
  }

  @override
  void dispose() {
    NativeBridge.setSecureScreen(false);
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.phrase));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Encryption phrase copied.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SurfaceCard(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Encryption phrase QR',
                          style: text.titleMedium),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: widget.phrase,
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppTheme.charcoal,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppTheme.charcoal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SelectableText(
                  widget.phrase,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                const InfoBanner(
                  icon: Icons.warning_amber_rounded,
                  tone: BannerTone.error,
                  message:
                      'Anyone who scans this QR code can decrypt messages protected by this phrase. Do not show it in public or send a screenshot through an untrusted channel.',
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy encryption phrase'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
