import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:afrimarket_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_notifications_repository.dart';
import '../../../helpers/fake_realtime_connection.dart';
import '../../../helpers/fake_unread_counts_repository.dart';

/// Session fixée par le test.
class _Session extends SessionNotifier {
  new(this._initial);

  final SessionStatus _initial;

  @override
  SessionStatus build() => _initial;
}

/// Laisse passer les tâches en attente (chargements simulés).
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Result<CursorPage<AppNotification>> _page(
  List<String> ids, {
  String? next,
  bool read = false,
}) => Ok(
  CursorPage(
    items: [for (final id in ids) sampleNotification(id, read: read)],
    nextCursor: next,
  ),
);

void main() {
  late FakeNotificationsRepository notifications;
  late FakeRealtimeConnection realtime;
  late FakeUnreadCountsRepository unread;

  setUp(() {
    notifications = FakeNotificationsRepository();
    realtime = FakeRealtimeConnection();
    unread = FakeUnreadCountsRepository();
  });

  Future<ProviderContainer> start({
    SessionStatus session = SessionStatus.authenticated,
  }) async {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _Session(session)),
        ...notificationsOverrides(notifications),
        ...realtimeOverrides(realtime),
        ...unreadOverrides(unread),
      ],
    )..listen(notificationsControllerProvider, (_, _) {});
    addTearDown(container.dispose);
    await _settle();
    return container;
  }

  NotificationsController controller(ProviderContainer c) =>
      c.read(notificationsControllerProvider.notifier);

  NotificationsState state(ProviderContainer c) =>
      c.read(notificationsControllerProvider);

  test('visiteur : rien n’est demandé, onglet vu sans appel', () async {
    final c = await start(session: SessionStatus.unauthenticated);

    expect(state(c).isEmpty, isTrue);
    expect(notifications.listCalls, isEmpty);

    await controller(c).setVisible(visible: true);
    expect(notifications.seenCalls, 0);
  });

  test('première page, puis page suivante sans doublon', () async {
    notifications.pages
      ..clear()
      ..addAll([
        _page(['a', 'b'], next: 'b'),
        _page(['b', 'c']),
      ]);
    final c = await start();

    expect(state(c).items.map((n) => n.id), ['a', 'b']);
    expect(state(c).canLoadMore, isTrue);
    expect(state(c).hasUnread, isTrue);

    await controller(c).loadMore();

    expect(notifications.listCalls, [null, 'b']);
    expect(state(c).items.map((n) => n.id), ['a', 'b', 'c']);
    expect(state(c).canLoadMore, isFalse);
  });

  test('page suivante en échec : Réessayer', () async {
    notifications.pages
      ..clear()
      ..addAll([
        _page(['a'], next: 'a'),
        const Err(NetworkFailure()),
        _page(['b']),
      ]);
    final c = await start();

    await controller(c).loadMore();
    expect(state(c).loadMoreFailure, isA<NetworkFailure>());
    expect(state(c).canLoadMore, isFalse);

    await controller(c).retryLoadMore();
    expect(state(c).loadMoreFailure, isNull);
    expect(state(c).items.map((n) => n.id), ['a', 'b']);
  });

  test('premier chargement en échec, puis actualisation réussie', () async {
    notifications.pages
      ..clear()
      ..addAll([
        const Err(ServerFailure()),
        _page(['a']),
      ]);
    final c = await start();

    expect(state(c).phase, NotificationsPhase.failed);
    expect(state(c).failure, isA<ServerFailure>());

    await controller(c).refresh();

    expect(state(c).phase, NotificationsPhase.ready);
    expect(state(c).items.single.id, 'a');
  });

  test('actualisation en échec : la liste reste, message à afficher', () async {
    notifications.pages
      ..clear()
      ..addAll([
        _page(['a']),
        const Err(NetworkFailure()),
      ]);
    final c = await start();

    await controller(c).refresh();

    expect(state(c).items.single.id, 'a');
    expect(state(c).actionFailure, isA<NetworkFailure>());

    controller(c).actionFailureShown();
    expect(state(c).actionFailure, isNull);
  });

  test('onglet affiché : tout devient vu, pastille relue', () async {
    final c = await start();
    final before = unread.calls;

    await controller(c).setVisible(visible: true);
    await _settle();

    expect(notifications.seenCalls, 1);
    expect(unread.calls, greaterThan(before));

    await controller(c).setVisible(visible: false);
    expect(notifications.seenCalls, 1);
  });

  test(
    'notification en temps réel : liste relue, vue si onglet affiché',
    () async {
      notifications.pages
        ..clear()
        ..addAll([
          _page(['a']),
          _page(['new', 'a']),
          _page(['new2', 'new', 'a']),
        ]);
      final c = await start();

      realtime.emit(RealtimeEvent.notification);
      await _settle();
      expect(state(c).items.first.id, 'new');
      expect(notifications.seenCalls, 0);

      await controller(c).setVisible(visible: true);
      realtime
        ..emit(RealtimeEvent.message)
        ..emit(RealtimeEvent.notification);
      await _settle();

      expect(state(c).items.first.id, 'new2');
      expect(notifications.listCalls, hasLength(3));
      expect(notifications.seenCalls, 2);
    },
  );

  group('lecture', () {
    test('touchée : lue tout de suite, une seule fois', () async {
      notifications.pages
        ..clear()
        ..add(_page(['a', 'b']));
      final c = await start();

      await controller(c).markRead('a');
      await controller(c).markRead('a');
      await controller(c).markRead('inconnue');

      expect(notifications.readIds, ['a']);
      expect(state(c).items.first.read, isTrue);
      expect(state(c).items.last.read, isFalse);
    });

    test('échec : redevient non lue, message', () async {
      notifications
        ..pages.clear()
        ..pages.add(_page(['a']))
        ..actionAnswer = const Err(NetworkFailure());
      final c = await start();

      await controller(c).markRead('a');

      expect(state(c).items.single.read, isFalse);
      expect(state(c).actionFailure, isA<NetworkFailure>());
    });

    test('déjà supprimée sur le serveur : reste lue, sans message', () async {
      notifications
        ..pages.clear()
        ..pages.add(_page(['a']))
        ..actionAnswer = const Err(NotFoundFailure());
      final c = await start();

      await controller(c).markRead('a');

      expect(state(c).items.single.read, isTrue);
      expect(state(c).actionFailure, isNull);
    });

    test('tout marquer comme lu, puis plus rien à faire', () async {
      notifications.pages
        ..clear()
        ..add(_page(['a', 'b']));
      final c = await start();

      await controller(c).markAllRead();
      await controller(c).markAllRead();

      expect(notifications.readAllCalls, 1);
      expect(state(c).hasUnread, isFalse);
    });

    test('tout marquer comme lu en échec : état d’avant', () async {
      notifications
        ..pages.clear()
        ..pages.add(_page(['a', 'b']))
        ..actionAnswer = const Err(ServerFailure());
      final c = await start();

      await controller(c).markAllRead();

      expect(state(c).items.every((n) => !n.read), isTrue);
      expect(state(c).actionFailure, isA<ServerFailure>());
    });
  });

  group('suppression', () {
    test('retirée, remise par Annuler à sa place', () async {
      notifications.pages
        ..clear()
        ..add(_page(['a', 'b', 'c']));
      final c = await start();
      final b = state(c).items[1];

      final index = controller(c).remove('b');
      expect(index, 1);
      expect(state(c).items.map((n) => n.id), ['a', 'c']);
      expect(controller(c).remove('inconnue'), -1);

      controller(c)
        ..restore(b, index)
        ..restore(b, index);
      expect(state(c).items.map((n) => n.id), ['a', 'b', 'c']);
      expect(notifications.deletedIds, isEmpty);
    });

    test('confirmée : supprimée sur le serveur', () async {
      notifications.pages
        ..clear()
        ..add(_page(['a', 'b']));
      final c = await start();
      final a = state(c).items.first;

      final index = controller(c).remove('a');
      await controller(c).confirmRemove(a, index);

      expect(notifications.deletedIds, ['a']);
      expect(state(c).items.map((n) => n.id), ['b']);
    });

    test('échec : elle revient, message', () async {
      notifications
        ..pages.clear()
        ..pages.add(_page(['a', 'b']))
        ..actionAnswer = const Err(NetworkFailure());
      final c = await start();
      final b = state(c).items.last;

      final index = controller(c).remove('b');
      await controller(c).confirmRemove(b, index);

      expect(state(c).items.map((n) => n.id), ['a', 'b']);
      expect(state(c).actionFailure, isA<NetworkFailure>());
    });

    test('déjà supprimée sur le serveur : ne revient pas', () async {
      notifications
        ..pages.clear()
        ..pages.add(_page(['a']))
        ..actionAnswer = const Err(NotFoundFailure());
      final c = await start();
      final a = state(c).items.single;

      final index = controller(c).remove('a');
      await controller(c).confirmRemove(a, index);

      expect(state(c).isEmpty, isTrue);
      expect(state(c).actionFailure, isNull);
    });
  });
}
