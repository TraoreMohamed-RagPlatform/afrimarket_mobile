import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/blocked_person.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/person_report_reason.dart';
import 'package:afrimarket_mobile/features/safety/domain/repositories/safety_repository.dart';

/// Cas d'usage : se protéger d'une personne (comme Messenger).
///
/// Bloquer vaut dans les deux sens : plus de messages, et nos annonces ne
/// se voient plus. La personne n'est jamais prévenue.
class SafetyUseCases {
  const new(this._repository);

  final SafetyRepository _repository;

  Future<Result<List<BlockedPerson>>> blockedPeople() =>
      _repository.blockedPeople();

  Future<Result<void>> block(String userId) => _repository.block(userId);

  Future<Result<void>> unblock(String userId) => _repository.unblock(userId);

  /// Signale [userId]. Le détail est nettoyé ; vide, il n'est pas envoyé.
  Future<Result<void>> report({
    required String userId,
    required PersonReportReason reason,
    String details = '',
    String? conversationId,
  }) {
    final clean = details.trim();
    return _repository.report(
      userId: userId,
      reason: reason,
      details: clean.isEmpty ? null : clean,
      conversationId: conversationId,
    );
  }
}
