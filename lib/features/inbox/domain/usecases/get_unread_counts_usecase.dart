import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/inbox/domain/entities/unread_counts.dart';
import 'package:afrimarket_mobile/features/inbox/domain/repositories/unread_counts_repository.dart';

/// Cas d'usage : lire les compteurs de non-lus.
class GetUnreadCountsUseCase {
  const new(this._repository);

  final UnreadCountsRepository _repository;

  Future<Result<UnreadCounts>> call() => _repository.fetch();
}
