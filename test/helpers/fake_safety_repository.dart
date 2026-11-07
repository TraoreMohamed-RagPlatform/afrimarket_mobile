import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/blocked_person.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/person_report_reason.dart';
import 'package:afrimarket_mobile/features/safety/domain/repositories/safety_repository.dart';
import 'package:afrimarket_mobile/features/safety/safety_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// Faux dépôt « sécurité » : réponses configurables, appels mémorisés.
/// Par défaut : personne n'est bloqué, tout réussit.
class FakeSafetyRepository implements SafetyRepository {
  Result<List<BlockedPerson>> blockedAnswer = const Ok([]);
  Result<void> blockAnswer = const Ok(null);
  Result<void> unblockAnswer = const Ok(null);
  Result<void> reportAnswer = const Ok(null);

  int listCalls = 0;
  final blocked = <String>[];
  final unblocked = <String>[];
  final reports =
      <
        ({
          String userId,
          PersonReportReason reason,
          String? details,
          String? conversationId,
        })
      >[];

  /// Appelé à chaque blocage / déblocage (par exemple : changer la
  /// réponse du faux dépôt de messagerie).
  void Function()? onChange;

  @override
  Future<Result<List<BlockedPerson>>> blockedPeople() async {
    listCalls++;
    return blockedAnswer;
  }

  @override
  Future<Result<void>> block(String userId) async {
    blocked.add(userId);
    if (blockAnswer.isOk) onChange?.call();
    return blockAnswer;
  }

  @override
  Future<Result<void>> unblock(String userId) async {
    unblocked.add(userId);
    if (unblockAnswer.isOk) onChange?.call();
    return unblockAnswer;
  }

  @override
  Future<Result<void>> report({
    required String userId,
    required PersonReportReason reason,
    String? details,
    String? conversationId,
  }) async {
    reports.add((
      userId: userId,
      reason: reason,
      details: details,
      conversationId: conversationId,
    ));
    return reportAnswer;
  }
}

/// Remplace la sécurité de l'app : aucun appel au vrai serveur.
List<Override> safetyOverrides([FakeSafetyRepository? repository]) => [
  safetyRepositoryProvider.overrideWithValue(
    repository ?? FakeSafetyRepository(),
  ),
];

/// Personne bloquée de démonstration.
BlockedPerson sampleBlocked(String id, {String? name = 'Youssef B.'}) =>
    BlockedPerson(userId: id, name: name, blockedAt: DateTime(2026, 11, 7, 10));
