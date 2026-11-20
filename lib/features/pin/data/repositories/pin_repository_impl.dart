import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../domain/repositories/pin_repository.dart';
import '../datasources/pin_local_data_source.dart';

class PinRepositoryImpl implements PinRepository {
  PinRepositoryImpl(this._localDataSource);

  final PinLocalDataSource _localDataSource;

  // PBKDF2 is intentionally used instead of a fast general-purpose hash.
  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 600000,
    bits: 256,
  );

  static const int _maxAttempts = 5;
  static const int _lockoutSeconds = 30;

  @override
  Future<bool> hasPin() async =>
      (await _localDataSource.readHash()) != null &&
      (await _localDataSource.readSalt()) != null;

  String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  Future<String> _deriveHash(String pin, String salt) async {
    final key = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: base64Url.decode(salt),
    );
    return base64UrlEncode(await key.extractBytes());
  }

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError('PIN must contain exactly 6 digits.');
    }
  }

  @override
  Future<void> setupPin(String pin) async {
    _validatePin(pin);
    if (await hasPin()) {
      throw StateError('A PIN is already configured.');
    }
    final salt = _randomSalt();
    final hash = await _deriveHash(pin, salt);
    await _localDataSource.savePinMaterial(hash: hash, salt: salt);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    _validatePin(pin);

    final lockUntil = await _localDataSource.readLockUntil();
    if (lockUntil != null && DateTime.now().isBefore(lockUntil)) {
      final remaining = lockUntil.difference(DateTime.now()).inSeconds + 1;
      throw StateError('LOCKED:$remaining');
    }

    final storedHash = await _localDataSource.readHash();
    final salt = await _localDataSource.readSalt();
    if (storedHash == null || salt == null) return false;

    final enteredHash = await _deriveHash(pin, salt);
    final valid = storedHash == enteredHash;

    if (valid) {
      await _localDataSource.resetAttempts();
      return true;
    }

    final attempts = (await _localDataSource.readAttempts()) + 1;
    await _localDataSource.writeAttempts(attempts);

    if (attempts >= _maxAttempts) {
      await _localDataSource.writeAttempts(0);
      await _localDataSource.writeLockUntil(
        DateTime.now().add(const Duration(seconds: _lockoutSeconds)),
      );
    }
    return false;
  }

  @override
  Future<void> changePin(String currentPin, String newPin) async {
    _validatePin(newPin);
    final valid = await verifyPin(currentPin);
    if (!valid) throw StateError('Current PIN is incorrect.');

    final salt = _randomSalt();
    final hash = await _deriveHash(newPin, salt);
    await _localDataSource.savePinMaterial(hash: hash, salt: salt);
  }
}
