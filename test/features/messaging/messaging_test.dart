import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:afrimarket_mobile/features/messaging/data/repositories/messaging_repository_impl.dart';
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

  test('conversation créée, puis message envoyé', () async {
    server.respond([
      (200, {'id': 'conv-1', 'participants': <String>[]}),
      (201, {'message': 'ok'}),
    ]);

    final result = await messageSeller(
      sellerId: 'seller-1',
      message: '  Bonjour, est-ce toujours disponible ?  ',
    );

    expect(result.isOk, isTrue);
    final [conversation, message] = server.requests;
    expect(conversation.path, '/api/messages/conversations');
    expect(conversation.data, {'recipientId': 'seller-1'});
    expect(message.path, '/api/messages');
    expect(message.data, {
      'conversationId': 'conv-1',
      'content': 'Bonjour, est-ce toujours disponible ?',
    });
  });

  test('message vide ou trop long : refusé sans appel', () async {
    for (final text in ['   ', 'x' * (MessageSellerUseCase.maxLength + 1)]) {
      final result = await messageSeller(sellerId: 'seller-1', message: text);

      expect((result as Err).failure, isA<ValidationFailure>());
    }
    expect(server.requests, isEmpty);
  });

  test('identifiant de conversation invalide : rien n’est envoyé', () async {
    server.respond([
      (200, {'id': '../admin'}),
    ]);

    final result = await messageSeller(sellerId: 'seller-1', message: 'Salut');

    expect((result as Err).failure, isA<UnexpectedFailure>());
    expect(server.requests, hasLength(1));
  });

  test('à soi-même (400) : ValidationFailure', () async {
    server.respond([
      (400, {'error': 'Impossible'}),
    ]);

    final result = await messageSeller(sellerId: 'me', message: 'Salut');

    expect((result as Err).failure, isA<ValidationFailure>());
  });
}
