import '../repositories/pin_repository.dart';

class VerifyPin {
  const VerifyPin(this.repository);
  final PinRepository repository;

  Future<bool> call(String pin) => repository.verifyPin(pin);
}
