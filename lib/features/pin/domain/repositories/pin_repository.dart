abstract class PinRepository {
  Future<bool> hasPin();
  Future<void> setupPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> changePin(String currentPin, String newPin);
}
