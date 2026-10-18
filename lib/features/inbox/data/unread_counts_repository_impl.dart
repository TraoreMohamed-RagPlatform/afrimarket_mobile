import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/features/inbox/domain/entities/unread_counts.dart';
import 'package:afrimarket_mobile/features/inbox/domain/repositories/unread_counts_repository.dart';
import 'package:dio/dio.dart';

/// `GET /api/messages/unread-count` et `GET /api/notifications/unread-count`,
/// en parallèle.
class UnreadCountsRepositoryImpl implements UnreadCountsRepository {
  const new(this._dio);

  /// Plafond : la pastille affiche « 99+ » bien avant, inutile de croire
  /// un nombre absurde.
  static const maxCount = 9999;

  final Dio _dio;

  @override
  Future<Result<UnreadCounts>> fetch() {
    return guardApiCall(() async {
      final [messages, notifications] = await Future.wait([
        _count(ApiEndpoints.unreadMessages),
        _count(ApiEndpoints.unreadNotifications),
      ]);
      return UnreadCounts(messages: messages, notifications: notifications);
    });
  }

  Future<int> _count(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    final count = response.data?['count'];
    if (count is! int || count < 0) {
      throw const FormatException('Compteur invalide');
    }
    return count > maxCount ? maxCount : count;
  }
}
