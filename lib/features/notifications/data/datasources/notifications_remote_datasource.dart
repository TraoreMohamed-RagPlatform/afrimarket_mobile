import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/notifications/data/models/notifications_json.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:dio/dio.dart';

/// Source distante : `/api/notifications` (connexion requise).
class NotificationsRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  Uri get _baseUrl => Uri.parse(_dio.options.baseUrl);

  Future<CursorPage<AppNotification>> notifications({String? cursor}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
      queryParameters: {'cursor': ?cursor},
    );
    return NotificationsJson.page(response.data, _baseUrl);
  }

  Future<void> markAllSeen() => _dio.put<void>(ApiEndpoints.notificationsSeen);

  Future<void> markRead(String id) =>
      _dio.put<void>(ApiEndpoints.notificationRead(id));

  Future<void> markAllRead() =>
      _dio.put<void>(ApiEndpoints.notificationsReadAll);

  Future<void> delete(String id) =>
      _dio.delete<void>(ApiEndpoints.notification(id));
}
