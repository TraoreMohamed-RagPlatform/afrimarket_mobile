import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:afrimarket_mobile/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/domain/message_rules.dart';
import 'package:afrimarket_mobile/features/messaging/domain/usecases/conversation_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_server.dart';

Map<String, dynamic> _conversation({
  String id = 'c1',
  String role = 'buying',
  Object? listing = const {
    'id': 'l1',
    'title': 'Vélo de ville',
    'price': 900,
    'status': 'RESERVED',
    'photo': '/uploads/velo.jpg',
  },
  Object? otherUser = const {
    'id': 'u2',
    'name': 'Youssef B.',
    'avatar': null,
    'isIdentityVerified': true,
    'canReceiveMessages': true,
  },
  Object? lastMessage = const {
    'id': 'm1',
    'preview': 'D’accord pour samedi.',
    'isMine': true,
    'createdAt': '2026-10-21T10:00:00.000Z',
  },
  Object? unreadCount = 2,
}) => {
  'id': id,
  'role': role,
  'listing': listing,
  'otherUser': otherUser,
  'lastMessage': lastMessage,
  'lastMessageAt': '2026-10-21T10:00:00.000Z',
  'unreadCount': unreadCount,
};

Map<String, dynamic> _message(String id, {bool mine = false}) => {
  'id': id,
  'content': 'Texte $id',
  'senderId': mine ? 'me' : 'other',
  'isMine': mine,
  'createdAt': '2026-10-21T10:00:00.000Z',
  'readAt': mine ? '2026-10-21T10:05:00.000Z' : null,
};

void main() {
  late FakeHttpServer server;
  late MessagingRepositoryImpl repository;

  setUp(() {
    server = FakeHttpServer();
    repository = MessagingRepositoryImpl(
      MessagingRemoteDataSource(server.client()),
    );
  });

  group('Discussions', () {
    test('onglet et curseur envoyés ; discussion lue en entier', () async {
      server.respond([
        (
          200,
          {
            'conversations': [_conversation()],
            'nextCursor': 'c1',
          },
        ),
      ]);

      final result = await repository.conversations(
        role: ConversationRole.selling,
        cursor: 'c0',
      );

      final request = server.requests.single;
      expect(request.path, '/api/messages/conversations');
      expect(request.queryParameters, {'role': 'selling', 'cursor': 'c0'});
      final page = (result as Ok<CursorPage<ConversationSummary>>).value;
      expect(page.nextCursor, 'c1');
      final item = page.items.single;
      expect(item.role, ConversationRole.buying);
      expect(item.unreadCount, 2);
      expect(item.listing?.status, ConversationListingStatus.reserved);
      expect(
        item.listing?.photoUrl,
        'https://api.example.com/uploads/velo.jpg',
      );
      expect(item.otherUser.name, 'Youssef B.');
      expect(item.otherUser.isIdentityVerified, isTrue);
      expect(item.lastMessage?.isMine, isTrue);
      expect(item.lastMessage?.sentAt, DateTime.utc(2026, 10, 21, 10));
    });

    test('sans curseur : seul l’onglet est envoyé', () async {
      server.respond([
        (200, {'conversations': <Object>[], 'nextCursor': null}),
      ]);

      final result = await repository.conversations(
        role: ConversationRole.buying,
      );

      expect(server.requests.single.queryParameters, {'role': 'buying'});
      expect(
        (result as Ok<CursorPage<ConversationSummary>>).value.hasMore,
        isFalse,
      );
    });

    test('éléments mal formés ignorés, valeurs prudentes', () async {
      server.respond([
        (
          200,
          {
            'conversations': [
              'texte',
              _conversation(id: '../x'),
              _conversation(id: 'c2', role: 'admin'),
              _conversation(id: 'c3', otherUser: null),
              _conversation(
                id: 'ok',
                listing: {
                  'id': 'l2',
                  'title': 'Lampe',
                  'price': -5,
                  'status': 'BIZARRE',
                  'photo': 'javascript:alert(1)',
                },
                otherUser: {
                  'id': 'u9',
                  'name': null,
                  'canReceiveMessages': false,
                },
                lastMessage: {'preview': '', 'createdAt': 'pas une date'},
                unreadCount: -3,
              ),
              _conversation(id: 'sans-annonce', listing: {'id': 'l3'}),
            ],
            'nextCursor': '../evil',
          },
        ),
      ]);

      final result = await repository.conversations(
        role: ConversationRole.buying,
      );
      final page = (result as Ok<CursorPage<ConversationSummary>>).value;

      expect(page.items.map((c) => c.id), ['ok', 'sans-annonce']);
      expect(page.nextCursor, isNull);
      final ok = page.items.first;
      expect(ok.listing?.price, 0);
      expect(ok.listing?.status, ConversationListingStatus.unavailable);
      expect(ok.listing?.photoUrl, isNull);
      expect(ok.otherUser.isDeleted, isTrue);
      expect(ok.otherUser.canReceiveMessages, isFalse);
      expect(ok.lastMessage, isNull);
      expect(ok.unreadCount, 0);
      expect(page.items.last.listing, isNull);
    });

    test('réponse sans liste : UnexpectedFailure', () async {
      server.respond([
        (200, {'items': <Object>[]}),
      ]);

      final result = await repository.conversations(
        role: ConversationRole.buying,
      );

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });

    test('en-tête : lu ; mal formé : UnexpectedFailure ; 404', () async {
      server.respond([
        (200, _conversation(role: 'selling')),
        (200, {'id': 'c1'}),
        (404, {'error': 'Conversation not found'}),
      ]);

      final ok = await repository.conversation('c1');
      final bad = await repository.conversation('c1');
      final missing = await repository.conversation('c1');

      expect(server.requests.first.path, '/api/messages/conversations/c1');
      expect(
        (ok as Ok<ConversationSummary>).value.role,
        ConversationRole.selling,
      );
      expect((bad as Err).failure, isA<UnexpectedFailure>());
      expect((missing as Err).failure, isA<NotFoundFailure>());
    });
  });

  group('Messages', () {
    test('page lue, curseur « before » envoyé', () async {
      server.respond([
        (
          200,
          {
            'messages': [
              _message('m2', mine: true),
              _message('m1'),
              {'id': 'vide', 'content': '', 'createdAt': '2026-10-21'},
            ],
            'nextCursor': 'm1',
          },
        ),
      ]);

      final result = await repository.messages('c1', before: 'm3');

      final request = server.requests.single;
      expect(request.path, '/api/messages/c1');
      expect(request.queryParameters, {'before': 'm3'});
      final page = (result as Ok<CursorPage<ChatMessage>>).value;
      expect(page.items.map((m) => m.id), ['m2', 'm1']);
      expect(page.items.first.isMine, isTrue);
      expect(page.items.first.readAt, isNotNull);
      expect(page.items.last.readAt, isNull);
      expect(page.nextCursor, 'm1');
    });

    test('envoi : discussion et texte ; message renvoyé', () async {
      server.respond([(201, _message('m9', mine: true))]);
      final send = SendMessageUseCase(repository);

      final result = await send(conversationId: 'c1', text: '  Bonjour  ');

      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/messages');
      expect(request.data, {'conversationId': 'c1', 'content': 'Bonjour'});
      expect((result as Ok<ChatMessage>).value.id, 'm9');
    });

    test('envoi : vide ou trop long refusé sans appel', () async {
      final send = SendMessageUseCase(repository);

      for (final text in ['  ', 'x' * (MessageRules.maxLength + 1)]) {
        final result = await send(conversationId: 'c1', text: text);
        expect((result as Err).failure, isA<ValidationFailure>());
      }
      expect(server.requests, isEmpty);
    });

    test('envoi : réponse mal formée → UnexpectedFailure', () async {
      server.respond([
        (201, {'id': 'm9'}),
      ]);

      final result = await repository.send(conversationId: 'c1', text: 'Hi');

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });

    test('use cases : liste, en-tête et messages passent au dépôt', () async {
      server.respond([
        (200, {'conversations': <Object>[]}),
        (200, _conversation()),
        (200, {'messages': <Object>[]}),
      ]);

      await GetConversationsUseCase(repository)(role: ConversationRole.buying);
      await GetConversationUseCase(repository)('c1');
      await GetMessagesUseCase(repository)('c1');

      expect(server.requests.map((r) => r.path), [
        '/api/messages/conversations',
        '/api/messages/conversations/c1',
        '/api/messages/c1',
      ]);
    });
  });

  test('MessageRules : nettoyage et limites', () {
    expect(MessageRules.clean('  Salut \n'), 'Salut');
    expect(MessageRules.clean('   '), isNull);
    expect(MessageRules.clean('é' * MessageRules.maxLength), isNotNull);
    expect(MessageRules.clean('é' * (MessageRules.maxLength + 1)), isNull);
  });

  test('ConversationSummary.markedRead : pastille à zéro', () {
    const summary = ConversationSummary(
      id: 'c1',
      role: ConversationRole.buying,
      otherUser: ConversationPerson(id: 'u1', name: 'A'),
      unreadCount: 3,
    );

    expect(summary.markedRead().unreadCount, 0);
    expect(summary.markedRead().id, 'c1');
    const read = ConversationSummary(
      id: 'c2',
      role: ConversationRole.selling,
      otherUser: ConversationPerson(id: 'u1'),
    );
    expect(identical(read.markedRead(), read), isTrue);
  });
}
