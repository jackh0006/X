import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';

import 'api.dart';

typedef _EncryptNative = Pointer<Utf8> Function(
  Pointer<Uint8>,
  UintPtr,
  Pointer<Uint8>,
  UintPtr,
  Uint32,
);
typedef _EncryptDart = Pointer<Utf8> Function(
  Pointer<Uint8>,
  int,
  Pointer<Uint8>,
  int,
  int,
);
typedef _DecryptNative = Int32 Function(
  Pointer<Uint8>,
  UintPtr,
  Pointer<Uint8>,
  UintPtr,
  Pointer<Uint8>,
  UintPtr,
  Pointer<UintPtr>,
);
typedef _DecryptDart = int Function(
  Pointer<Uint8>,
  int,
  Pointer<Uint8>,
  int,
  Pointer<Uint8>,
  int,
  Pointer<UintPtr>,
);
typedef _PayloadNative = Pointer<Utf8> Function(Pointer<Uint8>, UintPtr);
typedef _PayloadDart = Pointer<Utf8> Function(Pointer<Uint8>, int);
typedef _GenerateNative = Pointer<Utf8> Function(Uint32);
typedef _GenerateDart = Pointer<Utf8> Function(int);
typedef _VersionNative = Pointer<Utf8> Function();
typedef _FreeNative = Void Function(Pointer<Utf8>);
typedef _FreeDart = void Function(Pointer<Utf8>);

class _Bindings {
  _Bindings._() : _lib = _open() {
    _encrypt = _lib.lookupFunction<_EncryptNative, _EncryptDart>('x_encrypt');
    _decrypt = _lib.lookupFunction<_DecryptNative, _DecryptDart>('x_decrypt');
    _inspect = _lib.lookupFunction<_PayloadNative, _PayloadDart>('x_inspect');
    _generate = _lib.lookupFunction<_GenerateNative, _GenerateDart>(
      'x_generate_passphrase',
    );
    _version = _lib.lookupFunction<_VersionNative, _VersionNative>(
      'x_core_version',
    );
    _free = _lib.lookupFunction<_FreeNative, _FreeDart>('x_free_string');
  }

  static final _Bindings instance = _Bindings._();

  final DynamicLibrary _lib;
  late final _EncryptDart _encrypt;
  late final _DecryptDart _decrypt;
  late final _PayloadDart _inspect;
  late final _GenerateDart _generate;
  late final _VersionNative _version;
  late final _FreeDart _free;

  static DynamicLibrary _open() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libx_core.so');
    }
    if (Platform.isLinux) {
      final executable = File(Platform.resolvedExecutable);
      final bundled = File('${executable.parent.path}/lib/libx_core.so');
      if (bundled.existsSync()) {
        return DynamicLibrary.open(bundled.path);
      }
      final development = File(
        '${Directory.current.path}/../core/target/release/libx_core.so',
      );
      if (development.existsSync()) {
        return DynamicLibrary.open(development.absolute.path);
      }
      return DynamicLibrary.open('libx_core.so');
    }
    throw UnsupportedError('X supports Android and Linux.');
  }
}

class NativeXService implements XService {
  const NativeXService();

  @override
  Future<String> encrypt({
    required String plaintext,
    required String passphrase,
    required SecurityProfile profile,
  }) => Isolate.run(() => _encryptSync(plaintext, passphrase, profile.wireId));

  @override
  Future<String> decrypt({
    required String payload,
    required String passphrase,
  }) => Isolate.run(() => _decryptSync(payload, passphrase));

  @override
  Future<String> generatePassphrase({int words = 7}) =>
      Isolate.run(() => _generateSync(words));

  @override
  Future<PayloadInfo> inspect(String payload) =>
      Isolate.run(() => _inspectSync(payload));

  @override
  String get coreVersion => _versionString();

  static const int _maxPlaintextBytes = 64 * 1024;
  static const int _maxPassphraseBytes = 1024;

  static void _checkUtf8Size(
    String text,
    int max,
    String code,
    String message,
  ) {
    if (utf8.encode(text).length > max) {
      throw XFailure(code, message);
    }
  }
}

String _encryptSync(String plaintext, String passphrase, int profileId) {
  NativeXService._checkUtf8Size(
    plaintext,
    NativeXService._maxPlaintextBytes,
    'MESSAGE_TOO_LARGE',
    'The message is too large (limit 64 KiB).',
  );
  NativeXService._checkUtf8Size(
    passphrase,
    NativeXService._maxPassphraseBytes,
    'PASSPHRASE_TOO_LONG',
    'The passphrase must be at most 1024 characters.',
  );
  final message = utf8.encode(plaintext);
  final pass = utf8.encode(passphrase);
  final messagePtr = _alloc(message);
  final passPtr = _alloc(pass);
  try {
    final result = _Bindings.instance._encrypt(
      messagePtr,
      message.length,
      passPtr,
      pass.length,
      profileId,
    );
    return _value(result);
  } finally {
    _freeSensitive(messagePtr, message.length);
    _freeSensitive(passPtr, pass.length);
  }
}

String _decryptSync(String payload, String passphrase) {
  NativeXService._checkUtf8Size(
    passphrase,
    NativeXService._maxPassphraseBytes,
    'PASSPHRASE_TOO_LONG',
    'The passphrase must be at most 1024 characters.',
  );
  final payloadBytes = utf8.encode(payload);
  final pass = utf8.encode(passphrase);
  final payloadPtr = _alloc(payloadBytes);
  final passPtr = _alloc(pass);
  final outPtr = malloc<Uint8>(NativeXService._maxPlaintextBytes);
  final outLenPtr = malloc<UintPtr>();
  try {
    final status = _Bindings.instance._decrypt(
      payloadPtr,
      payloadBytes.length,
      passPtr,
      pass.length,
      outPtr,
      NativeXService._maxPlaintextBytes,
      outLenPtr,
    );
    if (status != 0) {
      throw _failureFor(status);
    }
    final length = outLenPtr.value;
    if (length > NativeXService._maxPlaintextBytes) {
      throw const XFailure('INTERNAL', 'Core returned an invalid length.');
    }
    final view = outPtr.asTypedList(length);
    final bytes = List<int>.from(view);
    view.fillRange(0, length, 0);
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const XFailure(
        'NON_UTF8',
        'The decrypted data is not valid UTF-8 text.',
      );
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  } finally {
    outPtr
        .asTypedList(NativeXService._maxPlaintextBytes)
        .fillRange(0, NativeXService._maxPlaintextBytes, 0);
    malloc.free(outPtr);
    malloc.free(outLenPtr);
    _freeSensitive(payloadPtr, payloadBytes.length);
    _freeSensitive(passPtr, pass.length);
  }
}

XFailure _failureFor(int code) {
  return switch (code) {
    1 => const XFailure('INVALID_FORMAT', 'Invalid encrypted text.'),
    2 => const XFailure(
      'UNSUPPORTED_VERSION',
      'Unsupported encrypted-text version. Update X and try again.',
    ),
    3 => const XFailure(
      'UNSUPPORTED_ALGORITHM',
      'Unsupported encryption algorithm. Update X and try again.',
    ),
    4 => const XFailure(
      'UNSUPPORTED_KDF',
      'Unsupported key-derivation method. Update X and try again.',
    ),
    5 => const XFailure(
      'INVALID_KDF_PARAMETERS',
      'The encrypted text contains unsafe KDF parameters.',
    ),
    6 => const XFailure(
      'PAYLOAD_TOO_LARGE',
      'The encrypted text is too large (limit 96 KiB).',
    ),
    7 => const XFailure(
      'MESSAGE_TOO_LARGE',
      'The message is too large (limit 64 KiB).',
    ),
    8 => const XFailure(
      'PASSPHRASE_TOO_SHORT',
      'The passphrase must be at least 8 characters.',
    ),
    9 => const XFailure(
      'PASSPHRASE_TOO_LONG',
      'The passphrase must be at most 1024 characters.',
    ),
    10 => const XFailure(
      'AUTHENTICATION_FAILED',
      'Wrong passphrase, or the encrypted text was modified or corrupted.',
    ),
    11 => const XFailure(
      'NON_UTF8',
      'The decrypted data is not valid UTF-8 text.',
    ),
    12 => const XFailure(
      'CRYPTO_FAILURE',
      'A cryptographic operation failed safely.',
    ),
    _ => const XFailure('INTERNAL', 'An internal error occurred.'),
  };
}

String _generateSync(int words) {
  final result = _Bindings.instance._generate(words);
  return _value(result);
}

PayloadInfo _inspectSync(String payload) {
  final bytes = utf8.encode(payload);
  final ptr = _alloc(bytes);
  try {
    final result = _Bindings.instance._inspect(ptr, bytes.length);
    final value = _value(result);
    final json = jsonDecode(value) as Map<String, dynamic>;
    return PayloadInfo.fromJson(json);
  } finally {
    _freeInput(ptr);
  }
}

String _versionString() {
  final ptr = _Bindings.instance._version();
  if (ptr == nullptr) return 'unknown';
  return ptr.toDartString();
}

Pointer<Uint8> _alloc(List<int> bytes) {
  if (bytes.isEmpty) return nullptr;
  final ptr = malloc<Uint8>(math.max(1, bytes.length));
  ptr.asTypedList(bytes.length).setAll(0, bytes);
  return ptr;
}

void _freeSensitive(Pointer<Uint8> ptr, int length) {
  if (ptr != nullptr) {
    if (length > 0) ptr.asTypedList(length).fillRange(0, length, 0);
    malloc.free(ptr);
  }
}

void _freeInput(Pointer<Uint8> ptr) {
  if (ptr != nullptr) malloc.free(ptr);
}

String _value(Pointer<Utf8> pointer) {
  if (pointer == nullptr) {
    throw const XFailure('INTERNAL', 'The encryption core did not respond.');
  }
  try {
    final raw = pointer.toDartString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const XFailure('INTERNAL', 'Malformed core response.');
    }
    if (decoded['ok'] != true) {
      throw XFailure(
        decoded['code'] as String? ?? 'INTERNAL',
        decoded['message'] as String? ?? 'An internal error occurred.',
      );
    }
    return decoded['value'] as String;
  } on FormatException {
    throw const XFailure('INTERNAL', 'Malformed core response.');
  } finally {
    _Bindings.instance._free(pointer);
  }
}
