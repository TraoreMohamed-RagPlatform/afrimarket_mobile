import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:afrimarket_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:afrimarket_mobile/features/notifications/notifications_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// Faux dépôt de notifications : réponses configurables, appels mémorisés.
/// Par défaut : aucune notification.
class FakeNotificationsRepository implements NotificationsRepository {
  /// Pages successives (la dernière est reprise).
  final pages = <Result<CursorPage<AppNotification>>>[
    const Ok(CursorPage(items: [])),
  ];
  final listCalls = <String?>[];

  int seenCalls = 0;
  final readIds = <String>[];
  int readAllCalls = 0;
  final deletedIds = <String>[];

  Result<void> actionAnswer = const Ok(null);

  @override
  Future<Result<CursorPage<AppNotification>>> notifications({
    String? cursor,
  }) async {
    listCalls.add(cursor);
    return pages.length > 1 ? pages.removeAt(0) : pages.first;
  }

  @override
  Future<Result<void>> markAllSeen() async {
    seenCalls++;
    return const Ok(null);
  }

  @override
  Future<Result<void>> markRead(String id) async {
    readIds.add(id);
    return actionAnswer;
  }

  @override
  Future<Result<void>> markAllRead() async {
    readAllCalls++;
    return actionAnswer;
  }

  @override
  Future<Result<void>> delete(String id) async {
    deletedIds.add(id);
    return actionAnswer;
  }
}

/// Remplace les notifications de l'app : aucun appel au vrai serveur.
List<Override> notificationsOverrides([
  FakeNotificationsRepository? repository,
]) => [
  notificationsRepositoryProvider.overrideWithValue(
    repository ?? FakeNotificationsRepository(),
  ),
];

/// Notification de démonstration.
AppNotification sampleNotification(
  String id, {
  NotificationKind kind = NotificationKind.listingInterest,
  bool read = false,
  bool withListing = true,
  String title = '',
  String message = '',
  DateTime? createdAt,
}) => AppNotification(
  id: id,
  kind: kind,
  createdAt: createdAt ?? DateTime.now(),
  read: read,
  title: title,
  message: message,
  listing: withListing
      ? const NotificationListing(
          id: 'listing-1',
          title: 'Canapé 3 places',
          status: NotificationListingStatus.available,
        )
      : null,
);
