import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:afrimarket_mobile/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:afrimarket_mobile/features/messaging/domain/messaging_conflicts.dart';
import 'package:afrimarket_mobile/features/messaging/domain/usecases/message_seller_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_server.dart';

void main() {
  late FakeHttpServer server;
  late MessageSellerUseCase messageSeller;

  setUp(() {
    server = FakeHttpServer();
    messageSeller = MessageSellerUseCase(
      MessagingRepositoryImpl(MessagingRemoteDataSource(server.client())),
    );
  });

  test('discussion de l’annonce ouverte, puis message envoyé', () async {
    server.respond([
      (201, {'id': 'conv-1', 'role': 'buying'}),
      (201, {'id': 'm1'}),
    ]);

    final result = await messageSeller(
      listingId: 'listing-1',
      message: '  Bonjour, est-ce toujours disponible ?  ',
    );

    expect(result.isOk, isTrue);
    final [conversation, message] = server.requests;
    expect(conversation.path, '/api/messages/conversations');
    // Seule l'annonce est envoyée : le serveur déduit acheteur et vendeur.
    expect(conversation.data, {'listingId': 'listing-1'});
    expect(message.path, '/api/messages');
    expect(message.data, {
      'conversationId': 'conv-1',
      'content': 'Bonjour, est-ce toujours disponible ?',
    });
  });

  test('message vide ou trop long : refusé sans appel', () async {
    for (final text in ['   ', 'x' * (MessageSellerUseCase.maxLength + 1)]) {
      final result = await messageSeller(listingId: 'listing-1', message: text);

      expect((result as Err).failure, isA<ValidationFailure>());
    }
    expect(server.requests, isEmpty);
  });

  test('identifiant de conversation invalide : rien n’est envoyé', () async {
    server.respond([
      (200, {'id': '../admin'}),
    ]);

    final result = await messageSeller(
      listingId: 'listing-1',
      message: 'Salut',
    );

    expect((result as Err).failure, isA<UnexpectedFailure>());
    expect(server.requests, hasLength(1));
  });

  test('sa propre annonce (400) : ValidationFailure', () async {
    server.respond([
      (400, {'error': 'Impossible', 'code': 'OWN_LISTING'}),
    ]);

    final result = await messageSeller(listingId: 'mine', message: 'Salut');

    expect((result as Err).failure, isA<ValidationFailure>());
    expect(server.requests, hasLength(1));
  });

  test('annonce vendue (409) : ConflictFailure avec son code', () async {
    server.respond([
      (409, {'error': 'x', 'code': MessagingConflicts.listingUnavailable}),
    ]);

    final result = await messageSeller(
      listingId: 'listing-1',
      message: 'Salut',
    );

    final failure = (result as Err).failure as ConflictFailure;
    expect(failure.code, MessagingConflicts.listingUnavailable);
    expect(server.requests, hasLength(1));
  });
}
