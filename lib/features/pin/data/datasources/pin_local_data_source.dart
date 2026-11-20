import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinLocalDataSource {
  PinLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  static const _hashKey = 'pin_hash';
  static const _saltKey = 'pin_salt';
  static const _attemptsKey = 'pin_failed_attempts';
  static const _lockUntilKey = 'pin_lock_until';

  Future<String?> readHash() => _storage.read(key: _hashKey);
  Future<String?> readSalt() => _storage.read(key: _saltKey);

  Future<void> savePinMaterial({
    required String hash,
    required String salt,
  }) async {
    await _storage.write(key: _hashKey, value: hash);
    await _storage.write(key: _saltKey, value: salt);
    await resetAttempts();
  }

  Future<int> readAttempts() async =>
      int.tryParse(await _storage.read(key: _attemptsKey) ?? '0') ?? 0;

  Future<void> writeAttempts(int value) =>
      _storage.write(key: _attemptsKey, value: value.toString());

  Future<DateTime?> readLockUntil() async {
    final value = await _storage.read(key: _lockUntilKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> writeLockUntil(DateTime? value) async {
    if (value == null) {
      await _storage.delete(key: _lockUntilKey);
    } else {
      await _storage.write(key: _lockUntilKey, value: value.toIso8601String());
    }
  }

  Future<void> resetAttempts() async {
    await _storage.write(key: _attemptsKey, value: '0');
    await writeLockUntil(null);
  }
}
