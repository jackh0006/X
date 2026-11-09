import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/clipboard_guard.dart';
import '../core/native_bridge.dart';
import '../settings.dart';
import '../theme/app_theme.dart';
import '../widgets/info_banner.dart';
import '../widgets/phrase_qr_dialog.dart';
import '../widgets/page_body.dart';
import '../widgets/result_card.dart';
import '../widgets/section_heading.dart';
import '../widgets/surface_card.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key, required this.service, required this.settings});

  final XService service;
  final SettingsController settings;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _messageController = TextEditingController();
  final _passController = TextEditingController();
  SecurityProfile _profile = SecurityProfile.standard;
  bool _obscure = true;
  bool _busy = false;
  String? _result;
  String? _error;
  int _messageBytes = 0;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_messageChanged);
    _passController.addListener(_passChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_messageChanged);
    _passController.removeListener(_passChanged);
    _messageController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _messageChanged() {
    final bytes = utf8.encode(_messageController.text).length;
    if (bytes != _messageBytes) {
      setState(() => _messageBytes = bytes);
    }
  }

  void _passChanged() => setState(() {});

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _encrypt() async {
    final message = _messageController.text;
    final passphrase = _passController.text;
    if (message.isEmpty) {
      setState(() => _error = 'Enter a message first.');
      return;
    }
    if (utf8.encode(message).length > 64 * 1024) {
      setState(() => _error = 'The message is too large (limit 64 KiB).');
      return;
    }
    if (utf8.encode(passphrase).length < 8) {
      setState(() => _error = 'Use a passphrase of at least 8 characters.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final value = await widget.service.encrypt(
        plaintext: message,
        passphrase: passphrase,
        profile: _profile,
      );
      if (!mounted) return;
      _passController.clear();
      _messageController.clear();
      setState(() {
        _result = value;
        _obscure = true;
      });
      _snack('Encrypted locally. Plaintext and phrase cleared from this screen.');
    } on XFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not encrypt the message.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate() async {
    try {
      final passphrase = await widget.service.generatePassphrase();
      if (!mounted) return;
      setState(() {
        _passController.text = passphrase;
        _obscure = false;
        _error = null;
      });
      _snack('Strong passphrase generated. Share it separately.');
    } on XFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not generate a passphrase.');
    }
  }

  Future<void> _copy(String value, String message) async {
    await copySensitive(value);
    _snack('$message Clipboard cleanup attempted after 60 seconds.');
  }

  Future<void> _share() async {
    final value = _result;
    if (value == null) return;
    try {
      final shared = await NativeBridge.shareText(value);
      if (!shared) _snack('Sharing is not available on this platform.');
    } catch (_) {
      _snack('Could not open the share sheet.');
    }
  }

  Future<void> _save() async {
    final value = _result;
    if (value == null) return;
    final filename = widget.settings.exportName;
    if (Platform.isAndroid) {
      try {
        final saved = await NativeBridge.saveText(value, filename: filename);
        _snack(saved ? 'Encrypted text saved.' : 'Save canceled.');
      } catch (_) {
        _snack('Could not save the file.');
      }
      return;
    }
    try {
      final folder = widget.settings.exportFolder;
      if (folder != null && await Directory(folder).exists()) {
        await File('$folder/$filename').writeAsString(value, flush: true);
        _snack('Encrypted text saved.');
        return;
      }
      final location = await getSaveLocation(
        suggestedName: filename,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Text', extensions: ['txt']),
        ],
      );
      if (location == null) return;
      await File(location.path).writeAsString(value, flush: true);
      _snack('Encrypted text saved.');
    } catch (_) {
      _snack('Could not save the file.');
    }
  }

  void _clear() {
    _messageController.clear();
    _passController.clear();
    setState(() {
      _result = null;
      _error = null;
      _obscure = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strength = _strength(_passController.text);
    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'Send',
          title: 'Seal a message.',
          subtitle:
              'Write anything sensitive, protect it with a passphrase, and send the encrypted text through any messenger or email.',
        ),
        const VGap(22),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(
                'MESSAGE',
                trailing: Text(
                  '$_messageBytes / 65536 bytes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _messageBytes > 65536
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                ),
              ),
              TextField(
                key: const Key('send-message'),
                controller: _messageController,
                minLines: 6,
                maxLines: 10,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                
                decoration: const InputDecoration(
                  hintText: 'Write or paste the message you want to protect…',
                ),
              ),
            ],
          ),
        ),
        const VGap(14),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(
                'PASSPHRASE',
                trailing: Text(
                  'Never included in the output',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              TextField(
                key: const Key('send-passphrase'),
                controller: _passController,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                
                decoration: InputDecoration(
                  hintText: 'Enter a strong passphrase…',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: _obscure ? 'Show passphrase' : 'Hide passphrase',
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      IconButton(
                        tooltip: 'Copy passphrase',
                        icon: const Icon(Icons.copy_rounded, size: 19),
                        onPressed: _passController.text.isEmpty
                            ? null
                            : () => _copy(
                                  _passController.text,
                                  'Passphrase copied. Share it separately.',
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              const VGap(12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy ? null : _generate,
                  child: const Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 18),
                      Text('Generate strong passphrase'),
                    ],
                  ),
                ),
              ),
              if (_passController.text.isNotEmpty) ...[
                const VGap(14),
                _StrengthMeter(strength: strength),
                const VGap(12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('send-qr'),
                    onPressed: () => showPhraseQrDialog(
                        context, _passController.text),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Show encryption phrase QR'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const VGap(14),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel('KEY STRENGTH'),
              SegmentedButton<SecurityProfile>(
                segments: const [
                  ButtonSegment(
                    value: SecurityProfile.standard,
                    label: Text('Standard'),
                  ),
                  ButtonSegment(
                    value: SecurityProfile.high,
                    label: Text('High'),
                  ),
                ],
                selected: {_profile},
                showSelectedIcon: false,
                onSelectionChanged: _busy
                    ? null
                    : (selection) =>
                        setState(() => _profile = selection.first),
              ),
              const VGap(10),
              Text(
                '${_profile.detail}. ${_profile.description}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
        const VGap(16),
        const InfoBanner(
          icon: Icons.key_off_rounded,
          tone: BannerTone.brand,
          message:
              'The passphrase is never embedded in the encrypted text. Send it to the recipient through a different channel, or agree on it in person.',
        ),
        const VGap(20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _encrypt,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.lock_rounded, size: 20),
            label: Text(_busy ? 'Encrypting…' : 'Encrypt message'),
          ),
        ),
        if (_error != null) ...[
          const VGap(16),
          InfoBanner(
            icon: Icons.error_outline_rounded,
            tone: BannerTone.error,
            message: _error!,
          ),
        ],
        if (_result != null) ...[
          const VGap(20),
          ResultCard(
            title: 'Encrypted text',
            value: _result!,
            monospace: true,
            onCopy: () => _copy(_result!, 'Encrypted text copied.'),
            footnote:
                'Portable text. The recipient still needs the separate passphrase.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _copy(_result!, 'Encrypted text copied.'),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
              ),
              if (NativeBridge.supportsShare)
                OutlinedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Share'),
                ),
              OutlinedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_alt_rounded, size: 18),
                label: const Text('Save'),
              ),
              TextButton(
                onPressed: _clear,
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  _Strength _strength(String value) {
    if (value.isEmpty) return const _Strength(0, 'Enter a passphrase', AppTheme.orange);
    final length = utf8.encode(value).length;
    var score = 0;
    if (length >= 8) score++;
    if (length >= 12) score++;
    if (length >= 16) score++;
    if (RegExp(r'[a-z]').hasMatch(value) &&
        RegExp(r'[A-Z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    if (value.split('-').length >= 6) score += 2;
    if (score <= 1) return const _Strength(1, 'Weak', Color(0xFFD14343));
    if (score <= 3) return const _Strength(2, 'Fair', AppTheme.orange);
    if (score <= 5) return const _Strength(3, 'Good', Color(0xFFD99A00));
    return const _Strength(4, 'Strong', Color(0xFF2E7D32));
  }
}

class _Strength {
  const _Strength(this.level, this.label, this.color);

  final int level;
  final String label;
  final Color color;
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final _Strength strength;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 4; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 5,
              decoration: BoxDecoration(
                color: i <= strength.level
                    ? strength.color
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (i != 4) const SizedBox(width: 6),
        ],
        const SizedBox(width: 12),
        Text(
          strength.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: strength.color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
