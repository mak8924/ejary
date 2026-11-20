import '../../../pin/domain/repositories/pin_repository.dart';
import '../../domain/repositories/startup_repository.dart';

class StartupRepositoryImpl implements StartupRepository {
  const StartupRepositoryImpl(this.pinRepository);
  final PinRepository pinRepository;

  @override
  Future<bool> hasPin() => pinRepository.hasPin();
}
