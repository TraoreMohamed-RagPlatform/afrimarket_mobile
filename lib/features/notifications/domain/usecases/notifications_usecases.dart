import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:afrimarket_mobile/features/notifications/domain/repositories/notifications_repository.dart';

/// Cas d'usage : mes notifications, page par page.
class GetNotificationsUseCase {
  const new(this._repository);

  final NotificationsRepository _repository;

  Future<Result<CursorPage<AppNotification>>> call({String? cursor}) =>
      _repository.notifications(cursor: cursor);
}

/// Cas d'usage : lire, voir, retirer des notifications.
class ManageNotificationsUseCase {
  const new(this._repository);

  final NotificationsRepository _repository;

  Future<Result<void>> markAllSeen() => _repository.markAllSeen();

  Future<Result<void>> markRead(String id) => _repository.markRead(id);

  Future<Result<void>> markAllRead() => _repository.markAllRead();

  Future<Result<void>> delete(String id) => _repository.delete(id);
}
