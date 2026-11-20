import '../repositories/pin_repository.dart';

class SetupPin {
  const SetupPin(this.repository);
  final PinRepository repository;

  Future<void> call(String pin) => repository.setupPin(pin);
}
