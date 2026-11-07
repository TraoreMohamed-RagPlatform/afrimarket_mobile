import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/features/safety/data/datasources/safety_remote_datasource.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/blocked_person.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/person_report_reason.dart';
import 'package:afrimarket_mobile/features/safety/domain/repositories/safety_repository.dart';

/// Implémentation du contrat [SafetyRepository].
class SafetyRepositoryImpl implements SafetyRepository {
  const new(this._remote);

  final SafetyRemoteDataSource _remote;

  @override
  Future<Result<List<BlockedPerson>>> blockedPeople() =>
      guardApiCall(_remote.blockedPeople);

  @override
  Future<Result<void>> block(String userId) =>
      guardApiCall(() => _remote.block(userId));

  @override
  Future<Result<void>> unblock(String userId) =>
      guardApiCall(() => _remote.unblock(userId));

  @override
  Future<Result<void>> report({
    required String userId,
    required PersonReportReason reason,
    String? details,
    String? conversationId,
  }) => guardApiCall(
    () => _remote.report(
      userId: userId,
      reason: reason,
      details: details,
      conversationId: conversationId,
    ),
  );
}
