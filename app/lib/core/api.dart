/// UI-facing contract for the Rust encryption core.
///
/// The widget layer never performs cryptography. Tests substitute a fake
/// implementation; the shipped app uses [NativeXService].
enum SecurityProfile { standard, high }

extension SecurityProfileX on SecurityProfile {
  int get wireId => this == SecurityProfile.standard ? 1 : 2;

  String get label => this == SecurityProfile.standard ? 'Standard' : 'High';

  String get detail => this == SecurityProfile.standard
      ? '128 MiB · 3 passes'
      : '256 MiB · 4 passes';

  String get description => this == SecurityProfile.standard
      ? 'Recommended. Resists guessing on phones and desktops.'
      : 'More expensive to guess. Slower on older phones.';
}

class XFailure implements Exception {
  const XFailure(this.code, this.message);

  final String code;
  final String message;

  bool get isAuthenticationFailure => code == 'AUTHENTICATION_FAILED';
  bool get isFormatFailure => const {
        'INVALID_FORMAT',
        'UNSUPPORTED_VERSION',
        'UNSUPPORTED_ALGORITHM',
        'UNSUPPORTED_KDF',
        'INVALID_KDF_PARAMETERS',
        'PAYLOAD_TOO_LARGE',
        'NON_UTF8',
      }.contains(code);

  @override
  String toString() => 'XFailure($code)';
}

class PayloadInfo {
  const PayloadInfo({
    required this.version,
    required this.opslimit,
    required this.memlimit,
    required this.ciphertextLength,
    required this.profile,
  });

  final int version;
  final int opslimit;
  final int memlimit;
  final int ciphertextLength;
  final SecurityProfile? profile;

  factory PayloadInfo.fromJson(Map<String, dynamic> json) => PayloadInfo(
        version: json['version'] as int,
        opslimit: json['opslimit'] as int,
        memlimit: json['memlimit'] as int,
        ciphertextLength: json['ciphertext_len'] as int,
        profile: switch (json['profile']) {
          1 => SecurityProfile.standard,
          2 => SecurityProfile.high,
          _ => null,
        },
      );
}

abstract class XService {
  Future<String> encrypt({
    required String plaintext,
    required String passphrase,
    required SecurityProfile profile,
  });

  Future<String> decrypt({
    required String payload,
    required String passphrase,
  });

  Future<String> generatePassphrase({int words = 7});

  Future<PayloadInfo> inspect(String payload);

  String get coreVersion;
}
