import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/blocked_person.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/person_report_reason.dart';

/// Contrat : bloquer, débloquer et signaler une personne (connexion requise).
abstract interface class SafetyRepository {
  /// Personnes que j'ai bloquées, les plus récentes d'abord.
  Future<Result<List<BlockedPerson>>> blockedPeople();

  /// Bloque [userId] (sans effet si déjà fait).
  Future<Result<void>> block(String userId);

  /// Débloque [userId] (sans effet si pas bloquée).
  Future<Result<void>> unblock(String userId);

  /// Signale [userId], depuis la discussion [conversationId] si fournie.
  Future<Result<void>> report({
    required String userId,
    required PersonReportReason reason,
    String? details,
    String? conversationId,
  });
}
