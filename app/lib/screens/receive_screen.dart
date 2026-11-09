import 'dart:async';

import 'package:flutter/material.dart';

import '../core/clipboard_guard.dart';

import '../core/api.dart';
import '../widgets/info_banner.dart';
import '../widgets/page_body.dart';
import '../widgets/result_card.dart';
import '../widgets/section_heading.dart';
import '../widgets/surface_card.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key, required this.service});

  final XService service;

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final _payloadController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _result;
  String? _error;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _payloadController.addListener(_changed);
    _passController.addListener(_changed);
    _armIdle();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _payloadController.removeListener(_changed);
    _passController.removeListener(_changed);
    _payloadController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _changed() => _armIdle();

  void _armIdle() {
    _idleTimer?.cancel();
    if (_payloadController.text.isEmpty &&
        _passController.text.isEmpty &&
        _result == null) {
      return;
    }
    _idleTimer = Timer(const Duration(minutes: 2), () {
      if (!mounted) return;
      _clear();
      _snack('Sensitive fields cleared after 2 minutes of inactivity.');
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _decrypt() async {
    final payload = _payloadController.text;
    final passphrase = _passController.text;
    if (payload.trim().isEmpty) {
      setState(() => _error = 'Paste the encrypted text first.');
      return;
    }
    if (passphrase.length < 8) {
      setState(() => _error = 'Enter the passphrase (at least 8 characters).');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final value = await widget.service.decrypt(
        payload: payload,
        passphrase: passphrase,
      );
      if (!mounted) return;
      setState(() {
        _result = value;
        _passController.clear();
      });
      _armIdle();
      _snack('Decrypted locally. Nothing was sent anywhere.');
    } on XFailure catch (failure) {
      if (!mounted) return;
      _passController.clear();
      setState(() => _error = failure.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not decrypt the message.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final value = _result;
    if (value == null) return;
    await copySensitive(value);
    _snack('Message copied. Clipboard cleanup attempted after 60 seconds.');
  }

  void _clear() {
    _idleTimer?.cancel();
    _payloadController.clear();
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
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _armIdle(),
      child: PageBody(
        children: [
          const SectionHeading(
            eyebrow: 'Receive',
            title: 'Open a sealed message.',
            subtitle: 'Paste the encrypted text and enter the passphrase you received separately. Verification happens here, on this device.',
          ),
          const VGap(22),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel('ENCRYPTED TEXT'),
                TextField(
                  key: const Key('receive-payload'),
                  controller: _payloadController,
                  minLines: 5,
                  maxLines: 9,
                  keyboardType: TextInputType.multiline,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    hintText: 'Paste the X1.… text here…',
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
                const FieldLabel('PASSPHRASE'),
                TextField(
                  key: const Key('receive-passphrase'),
                  controller: _passController,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  onSubmitted: (_) {
                    if (!_busy) _decrypt();
                  },
                  decoration: InputDecoration(
                    hintText: 'The passphrase you received…',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show passphrase' : 'Hide passphrase',
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const VGap(10),
                Text(
                  'Passphrases are case-sensitive. Spaces and punctuation must match exactly.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const VGap(16),
          const InfoBanner(
            icon: Icons.verified_user_outlined,
            tone: BannerTone.neutral,
            message: 'A failed check is never treated as success. If the text was altered or the passphrase is wrong, X refuses to show a message.',
          ),
          const VGap(10),
          const InfoBanner(
            icon: Icons.timer_outlined,
            tone: BannerTone.neutral,
            message: 'Decrypted text and fields clear after 2 minutes without typing or pointer activity.',
          ),
          const VGap(20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _decrypt,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.lock_open_rounded, size: 20),
              label: Text(_busy ? 'Verifying…' : 'Decrypt message'),
            ),
          ),
          if (_error != null) ...[
            const VGap(16),
            InfoBanner(
              icon: Icons.gpp_bad_outlined,
              tone: BannerTone.error,
              message: _error!,
            ),
          ],
          if (_result != null) ...[
            const VGap(20),
            ResultCard(
              title: 'Decrypted message',
              value: _result!,
              onCopy: _copy,
              footnote: 'Authenticated locally. This message was not uploaded.',
              actions: [
                OutlinedButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
                TextButton(onPressed: _clear, child: const Text('Clear')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
