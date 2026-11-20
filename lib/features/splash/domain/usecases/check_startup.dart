import '../repositories/startup_repository.dart';

class CheckStartup {
  const CheckStartup(this.repository);
  final StartupRepository repository;

  Future<bool> call() => repository.hasPin();
}
