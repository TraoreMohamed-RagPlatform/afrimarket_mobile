import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/features/health/data/datasources/health_remote_datasource.dart';
import 'package:afrimarket_mobile/features/health/domain/entities/health_status.dart';
import 'package:afrimarket_mobile/features/health/domain/repositories/health_repository.dart';

/// Implémentation du contrat [HealthRepository].
class HealthRepositoryImpl implements HealthRepository {
  const new(this._remote);

  final HealthRemoteDataSource _remote;

  @override
  Future<Result<HealthStatus>> check() {
    return guardApiCall(() async => (await _remote.fetch()).toEntity());
  }
}
