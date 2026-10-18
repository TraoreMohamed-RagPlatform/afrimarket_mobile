import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/inbox/domain/entities/unread_counts.dart';

/// Contrat : compteurs de non-lus (connexion requise).
abstract interface class UnreadCountsRepository {
  Future<Result<UnreadCounts>> fetch();
}
