import '../repositories/pin_repository.dart';

class HasPin {
  const HasPin(this.repository);
  final PinRepository repository;

  Future<bool> call() => repository.hasPin();
}
