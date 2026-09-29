import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/health/domain/entities/health_status.dart';

/// Contrat : vérifier la santé du serveur.
///
/// Défini dans le domaine, implémenté dans la couche data.
abstract interface class HealthRepository {
  Future<Result<HealthStatus>> check();
}
