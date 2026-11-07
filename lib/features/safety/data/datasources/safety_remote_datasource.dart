import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/features/safety/data/models/safety_json.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/blocked_person.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/person_report_reason.dart';
import 'package:dio/dio.dart';

/// Source distante : blocages et signalements (connexion requise).
class SafetyRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  Future<List<BlockedPerson>> blockedPeople() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.blocks);
    return SafetyJson.blocks(response.data, Uri.parse(_dio.options.baseUrl));
  }

  Future<void> block(String userId) =>
      _dio.post<void>(ApiEndpoints.blocks, data: {'userId': userId});

  Future<void> unblock(String userId) =>
      _dio.delete<void>(ApiEndpoints.block(userId));

  Future<void> report({
    required String userId,
    required PersonReportReason reason,
    String? details,
    String? conversationId,
  }) => _dio.post<void>(
    ApiEndpoints.reportUser(userId),
    data: {
      'reason': reason.apiValue,
      'details': ?details,
      'conversationId': ?conversationId,
    },
  );
}
