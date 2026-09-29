import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/health/domain/entities/health_status.dart';
import 'package:afrimarket_mobile/features/health/domain/repositories/health_repository.dart';

/// Cas d'usage : vérifier la santé du serveur.
class CheckHealthUseCase {
  const new(this._repository);

  final HealthRepository _repository;

  Future<Result<HealthStatus>> call() => _repository.check();
}
