import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:afrimarket_mobile/features/notifications/domain/repositories/notifications_repository.dart';

/// Implémentation du contrat [NotificationsRepository].
class NotificationsRepositoryImpl implements NotificationsRepository {
  const new(this._remote);

  final NotificationsRemoteDataSource _remote;

  @override
  Future<Result<CursorPage<AppNotification>>> notifications({String? cursor}) =>
      guardApiCall(() => _remote.notifications(cursor: cursor));

  @override
  Future<Result<void>> markAllSeen() => guardApiCall(_remote.markAllSeen);

  @override
  Future<Result<void>> markRead(String id) =>
      guardApiCall(() => _remote.markRead(id));

  @override
  Future<Result<void>> markAllRead() => guardApiCall(_remote.markAllRead);

  @override
  Future<Result<void>> delete(String id) =>
      guardApiCall(() => _remote.delete(id));
}
