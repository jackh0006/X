import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/clipboard_guard.dart';
import '../theme/app_theme.dart';
import 'info_banner.dart';
import 'surface_card.dart';

Future<void> showCiphertextQrDialog(BuildContext context, String ciphertext) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CiphertextQrDialog(ciphertext: ciphertext),
  );
}

class CiphertextQrDialog extends StatelessWidget {
  const CiphertextQrDialog({super.key, required this.ciphertext});

  final String ciphertext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
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
                      child: Text('Encrypted text QR', style: text.titleMedium),
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
                      data: ciphertext,
                      version: QrVersions.auto,
                      size: 270,
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
                const InfoBanner(
                  icon: Icons.info_outline_rounded,
                  tone: BannerTone.brand,
                  message:
                      'This QR contains the encrypted X1 text only. It does not contain the encryption phrase. Anyone with the phrase can decrypt it.',
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => copySensitive(ciphertext),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy encrypted text'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
