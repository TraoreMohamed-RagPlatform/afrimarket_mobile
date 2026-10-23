import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';

/// Contrat : mes notifications (connexion requise).
abstract interface class NotificationsRepository {
  /// Les plus récentes d'abord. [cursor] : page suivante.
  Future<Result<CursorPage<AppNotification>>> notifications({String? cursor});

  /// L'onglet est ouvert : la pastille s'efface (notifications « vues »).
  Future<Result<void>> markAllSeen();

  /// Notification touchée.
  Future<Result<void>> markRead(String id);

  /// Tout marquer comme lu.
  Future<Result<void>> markAllRead();

  /// Retirer une notification.
  Future<Result<void>> delete(String id);
}
