import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../data/donations.dart';
import '../settings.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/page_body.dart';
import '../widgets/section_heading.dart';
import '../widgets/surface_card.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key, required this.service, required this.settings});

  final XService service;
  final SettingsController settings;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late Future<StorageInfo> _storage;

  @override
  void initState() {
    super.initState();
    _storage = widget.settings.storageInfo();
  }

  void _refresh() {
    setState(() => _storage = widget.settings.storageInfo());
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    _snack('Path copied.');
  }

  Future<void> _chooseFolder() async {
    final folder = await widget.settings.chooseExportFolder();
    if (folder == null) {
      _snack('Folder selection canceled.');
      return;
    }
    _refresh();
    _snack('Export folder updated.');
  }

  Future<void> _rename() async {
    final controller =
        TextEditingController(text: widget.settings.exportName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export filename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Filename',
            helperText: 'Path separators are not allowed.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await widget.settings.setExportName(value);
    _refresh();
    _snack('Export filename updated.');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete local app data?'),
        content: const Text(
          'This removes X settings and cache on this device. Files you exported yourself are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.settings.deleteLocalData();
    _refresh();
    _snack('Local app data deleted.');
  }

  Future<void> _openFolder(String path) async {
    if (!Platform.isLinux) {
      _snack('Use your file manager to open this path.');
      return;
    }
    try {
      await Process.run('xdg-open', [path]);
    } catch (_) {
      _snack('Could not open the folder.');
    }
  }

  Widget _dataPath(
    BuildContext context,
    String label,
    String path,
    Future<void> Function(String) copy,
    Future<void> Function(String) open,
  ) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                tooltip: 'Copy $label path',
                visualDensity: VisualDensity.compact,
                onPressed: () => copy(path),
                icon: const Icon(Icons.copy_rounded, size: 16),
              ),
              if (Platform.isLinux)
                IconButton(
                  tooltip: 'Open $label folder',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => open(path),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                ),
            ],
          ),
          SelectableText(
            path,
            style: text.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

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
                      'Version 1.1.0 · build 3',
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
              Row(
                children: [
                  Icon(Icons.folder_outlined, color: scheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('Local data', style: text.titleMedium),
                ],
              ),
              const VGap(8),
              Text(
                'X stores no messages or plaintext. It stores only local settings and the cache. Ciphertext is saved only where you choose.',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const VGap(14),
              FutureBuilder<StorageInfo>(
                future: _storage,
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  if (info == null) {
                    return const LinearProgressIndicator();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dataPath(context, 'App data', info.dataPath, _copy, _openFolder),
                      _dataPath(context, 'Cache', info.cachePath, _copy, _openFolder),
                      _dataPath(context, 'Preferences', info.preferencesPath, _copy, _openFolder),
                      const VGap(10),
                      Text(
                        'Export folder: ${info.exportFolder ?? 'Choose a folder each time'}',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      Text(
                        'Export filename: ${info.exportName}',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const VGap(12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _chooseFolder,
                            icon: const Icon(Icons.create_new_folder_outlined, size: 17),
                            label: const Text('Choose export folder'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _rename,
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            label: const Text('Change filename'),
                          ),
                          TextButton.icon(
                            onPressed: _delete,
                            icon: const Icon(Icons.delete_outline_rounded, size: 17),
                            label: const Text('Delete local data'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
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
                'Format v1 · XChaCha20-Poly1305-IETF · Argon2id v1.3 · X core ${widget.service.coreVersion}',
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
