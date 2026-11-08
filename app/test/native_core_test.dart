@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:x/core/api.dart';
import 'package:x/core/native_x_service.dart';

void main() {
  final service = const NativeXService();

  setUpAll(() {
    if (!Platform.isLinux) {
      fail('Native core tests run on the Linux host only.');
    }
  });

  test('native FFI encrypts and decrypts Unicode text', () async {
    const message = 'Native FFI — 你好 — مرحبا — 🔐';
    const passphrase = 'correct horse battery staple';
    final payload = await service.encrypt(
      plaintext: message,
      passphrase: passphrase,
      profile: SecurityProfile.standard,
    );
    expect(payload, startsWith('X1.'));
    final plaintext =
        await service.decrypt(payload: payload, passphrase: passphrase);
    expect(plaintext, message);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('native FFI rejects a wrong passphrase', () async {
    final payload = await service.encrypt(
      plaintext: 'secret',
      passphrase: 'correct horse battery staple',
      profile: SecurityProfile.standard,
    );
    expect(
      () => service.decrypt(payload: payload, passphrase: 'wrong passphrase'),
      throwsA(isA<XFailure>().having(
          (e) => e.code, 'code', 'AUTHENTICATION_FAILED')),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('native FFI generates and inspects', () async {
    final passphrase = await service.generatePassphrase();
    expect(passphrase.split('-').length, 7);
    expect(service.coreVersion, isNotEmpty);

    final payload = await service.encrypt(
      plaintext: 'metadata',
      passphrase: passphrase,
      profile: SecurityProfile.high,
    );
    final info = await service.inspect(payload);
    expect(info.version, 1);
    expect(info.profile, SecurityProfile.high);
    expect(info.opslimit, 4);
    expect(info.memlimit, 256 * 1024 * 1024);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
