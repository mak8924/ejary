import '../repositories/pin_repository.dart';

class ChangePin {
  const ChangePin(this.repository);
  final PinRepository repository;

  Future<void> call(String currentPin, String newPin) =>
      repository.changePin(currentPin, newPin);
}
