import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:afrimarket_mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:afrimarket_mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_server.dart';

Map<String, dynamic> _notification(
  String id, {
  Object? type = 'LISTING_INTEREST',
  Object? listing = const {
    'id': 'l1',
    'title': 'Vélo',
    'status': 'RESERVED',
    'photo': '/uploads/velo.jpg',
  },
  bool read = false,
}) => {
  'id': id,
  'type': type,
  'title': 'Votre annonce intéresse',
  'message': 'Quelqu’un a enregistré votre annonce « Vélo ».',
  'read': read,
  'seen': true,
  'createdAt': '2026-10-23T09:00:00.000Z',
  'listing': listing,
};

void main() {
  late FakeHttpServer server;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    server = FakeHttpServer();
    repository = NotificationsRepositoryImpl(
      NotificationsRemoteDataSource(server.client()),
    );
  });

  test('liste : curseur envoyé, notification lue en entier', () async {
    server.respond([
      (
        200,
        {
          'notifications': [_notification('n1')],
          'nextCursor': 'n1',
        },
      ),
    ]);

    final result = await GetNotificationsUseCase(repository)(cursor: 'n0');

    final request = server.requests.single;
    expect(request.path, '/api/notifications');
    expect(request.queryParameters, {'cursor': 'n0'});
    final page = (result as Ok<CursorPage<AppNotification>>).value;
    expect(page.nextCursor, 'n1');
    final item = page.items.single;
    expect(item.kind, NotificationKind.listingInterest);
    expect(item.read, isFalse);
    expect(item.createdAt, DateTime.utc(2026, 10, 23, 9));
    expect(item.listing?.status, NotificationListingStatus.reserved);
    expect(item.listing?.photoUrl, 'https://api.example.com/uploads/velo.jpg');
  });

  test('types, valeurs prudentes, éléments mal formés ignorés', () async {
    server.respond([
      (
        200,
        {
          'notifications': [
            'texte',
            {'id': '../x', 'createdAt': '2026-10-23T09:00:00Z'},
            {'id': 'sans-date'},
            _notification('a', type: 'RATING_RECEIVED', read: true),
            _notification('b', type: 'LISTING_SOLD'),
            _notification('c', type: 'LISTING_UPDATED'),
            _notification('d', type: 'MESSAGE', listing: null),
            _notification(
              'e',
              type: 'INCONNU',
              listing: {
                'id': 'l2',
                'title': 'Lampe',
                'status': 'BIZARRE',
                'photo': 'javascript:alert(1)',
              },
            ),
            _notification('f', listing: {'id': 'l3'}),
          ],
          'nextCursor': '../evil',
        },
      ),
    ]);

    final result = await repository.notifications();
    final page = (result as Ok<CursorPage<AppNotification>>).value;

    expect(page.items.map((n) => n.id), ['a', 'b', 'c', 'd', 'e', 'f']);
    expect(page.items.map((n) => n.kind), [
      NotificationKind.ratingReceived,
      NotificationKind.listingSold,
      NotificationKind.listingUpdated,
      NotificationKind.message,
      NotificationKind.system,
      NotificationKind.listingInterest,
    ]);
    expect(page.items.first.read, isTrue);
    expect(
      page.items[4].listing?.status,
      NotificationListingStatus.unavailable,
    );
    expect(page.items[4].listing?.photoUrl, isNull);
    expect(page.items.last.listing, isNull);
    expect(page.nextCursor, isNull);
  });

  test('baisse de prix : type reconnu', () async {
    server.respond([
      (
        200,
        {
          'notifications': [_notification('p', type: 'PRICE_DROP')],
          'nextCursor': null,
        },
      ),
    ]);

    final result = await repository.notifications();

    final page = (result as Ok<CursorPage<AppNotification>>).value;
    expect(page.items.single.kind, NotificationKind.priceDrop);
  });

  test('réponse sans liste : UnexpectedFailure', () async {
    server.respond([
      (200, {'items': <Object>[]}),
    ]);

    final result = await repository.notifications();

    expect((result as Err).failure, isA<UnexpectedFailure>());
  });

  test('vues, lue, tout lu, suppression : bonnes routes', () async {
    server.respond([
      (200, {'updated': 1}),
      (200, {'read': true}),
      (200, {'updated': 2}),
      (204, null),
    ]);
    final manage = ManageNotificationsUseCase(repository);

    expect((await manage.markAllSeen()).isOk, isTrue);
    expect((await manage.markRead('n1')).isOk, isTrue);
    expect((await manage.markAllRead()).isOk, isTrue);
    expect((await manage.delete('n1')).isOk, isTrue);

    expect(server.requests.map((r) => '${r.method} ${r.path}'), [
      'PUT /api/notifications/seen',
      'PUT /api/notifications/n1/read',
      'PUT /api/notifications/read-all',
      'DELETE /api/notifications/n1',
    ]);
  });

  test('suppression d’une notification inconnue : NotFoundFailure', () async {
    server.respond([
      (404, {'error': 'Notification not found'}),
    ]);

    final result = await repository.delete('n9');

    expect((result as Err).failure, isA<NotFoundFailure>());
  });

  test('markedRead : lue, le reste identique', () {
    final item = AppNotification(
      id: 'n1',
      kind: NotificationKind.system,
      createdAt: DateTime(2026),
      title: 'T',
      message: 'M',
    );

    expect(item.markedRead().read, isTrue);
    expect(item.markedRead().title, 'T');
    final read = item.markedRead();
    expect(identical(read.markedRead(), read), isTrue);
  });
}
