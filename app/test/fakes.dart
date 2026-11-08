import 'package:x/core/api.dart';

class FakeXService implements XService {
  FakeXService();

  static const cannedPayload = 'X1.FAKE-PAYLOAD-FOR-WIDGET-TESTS';
  static const cannedPlaintext = 'The eagle lands at midnight.';
  static const generated = 'amber-brisk-cobalt-delta-ember-frost-glide';

  int encryptCalls = 0;
  int decryptCalls = 0;

  @override
  Future<String> encrypt({
    required String plaintext,
    required String passphrase,
    required SecurityProfile profile,
  }) async {
    encryptCalls++;
    if (passphrase.length < 8) {
      throw const XFailure(
          'PASSPHRASE_TOO_SHORT', 'The passphrase must be at least 8 characters.');
    }
    return cannedPayload;
  }

  @override
  Future<String> decrypt({
    required String payload,
    required String passphrase,
  }) async {
    decryptCalls++;
    if (!payload.startsWith('X1.')) {
      throw const XFailure(
          'INVALID_FORMAT', 'Invalid encrypted text: missing X1 prefix.');
    }
    if (passphrase != 'correct horse battery staple') {
      throw const XFailure('AUTHENTICATION_FAILED',
          'Wrong passphrase, or the encrypted text was modified or corrupted.');
    }
    return cannedPlaintext;
  }

  @override
  Future<String> generatePassphrase({int words = 7}) async => generated;

  @override
  Future<PayloadInfo> inspect(String payload) async => const PayloadInfo(
        version: 1,
        opslimit: 3,
        memlimit: 134217728,
        ciphertextLength: 64,
        profile: SecurityProfile.standard,
      );

  @override
  String get coreVersion => '1.0.1-test';
}
