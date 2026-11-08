import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:x/core/api.dart';
import 'package:x/core/native_x_service.dart';

/// Fixed fixture generated on Ubuntu AMD64 with the checked-in Rust core.
/// If this decrypts on Android, both platforms implement the same format.
const linuxFixture =
    'X1.WE1TRwEBAQAAAAMIAAAAAAECAwQFBgcICQoLDA0ODwABAgMEBQYHCAkKCwwNDg8QERITFBUWF_P7_ipwOXsGJqwFsblM9AasJnlcDGz9etRJ8g5mGduKzQAYbYoF6i3B9BqsnwBBW382bn3HHjXiLQDvzWIkR5UoTYk95CJutbzL4oF9nTxksg';
const fixturePlaintext =
    'Meet me at the old bridge at midnight. Bring the sealed envelope.';
const fixturePassphrase = 'correct horse battery staple';
const deviceMessage = 'Android to Linux interoperability check: 你好 🔐';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final service = const NativeXService();

  testWidgets('Linux-produced fixture decrypts on this device', (tester) async {
    final plaintext = await service.decrypt(
      payload: linuxFixture,
      passphrase: fixturePassphrase,
    );
    expect(plaintext, fixturePlaintext);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('this device produces a payload Linux can decrypt', (tester) async {
    final payload = await service.encrypt(
      plaintext: deviceMessage,
      passphrase: fixturePassphrase,
      profile: SecurityProfile.standard,
    );
    // CI captures this marker and decrypts it with the Linux core.
    // ignore: avoid_print
    print('X_INTEROP_CIPHERTEXT=$payload');
    final roundtrip = await service.decrypt(
      payload: payload,
      passphrase: fixturePassphrase,
    );
    expect(roundtrip, deviceMessage);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
