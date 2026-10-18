import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/inbox/domain/entities/unread_counts.dart';
import 'package:afrimarket_mobile/features/inbox/domain/repositories/unread_counts_repository.dart';
import 'package:afrimarket_mobile/features/inbox/inbox_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// Faux compteurs de non-lus : réponse configurable, appels comptés.
///
/// Par défaut : aucun message ni notification non lus.
class FakeUnreadCountsRepository implements UnreadCountsRepository {
  Result<UnreadCounts> answer = const Ok(UnreadCounts.zero);
  int calls = 0;

  @override
  Future<Result<UnreadCounts>> fetch() async {
    calls++;
    return answer;
  }
}

/// Remplace les compteurs de non-lus de l'app : aucun test ne doit
/// appeler le vrai serveur.
List<Override> unreadOverrides([FakeUnreadCountsRepository? repository]) => [
  unreadCountsRepositoryProvider.overrideWithValue(
    repository ?? FakeUnreadCountsRepository(),
  ),
];
