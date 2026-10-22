import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/cursor_page.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/controllers/chat_controller.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/controllers/conversations_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_messaging_repository.dart';
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

void main() {
  late FakeMessagingRepository messaging;
  late FakeRealtimeConnection realtime;
  late FakeUnreadCountsRepository unread;

  setUp(() {
    messaging = FakeMessagingRepository();
    realtime = FakeRealtimeConnection();
    unread = FakeUnreadCountsRepository();
  });

  ProviderContainer container({
    SessionStatus session = SessionStatus.authenticated,
  }) {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _Session(session)),
        ...messagingOverrides(messaging),
        ...realtimeOverrides(realtime),
        ...unreadOverrides(unread),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ConversationsController', () {
    final buying = conversationsControllerProvider(ConversationRole.buying);

    Future<ProviderContainer> start({
      SessionStatus session = SessionStatus.authenticated,
    }) async {
      final c = container(session: session)..listen(buying, (_, _) {});
      await _settle();
      return c;
    }

    test('visiteur : rien n’est demandé', () async {
      final c = await start(session: SessionStatus.unauthenticated);

      expect(c.read(buying).isEmpty, isTrue);
      expect(messaging.conversationCalls, isEmpty);
    });

    test('première page, puis page suivante sans doublon', () async {
      messaging.conversationsByRole[ConversationRole.buying] = CursorPage(
        items: [
          sampleConversation(),
          sampleConversation(id: 'c2', unread: 2),
        ],
        nextCursor: 'c2',
      );
      final c = await start();

      expect(c.read(buying).items, hasLength(2));
      expect(c.read(buying).unreadCount, 2);
      expect(c.read(buying).canLoadMore, isTrue);

      messaging.conversationsByRole[ConversationRole.buying] = CursorPage(
        items: [
          sampleConversation(id: 'c2'),
          sampleConversation(id: 'c3'),
        ],
      );
      await c.read(buying.notifier).loadMore();

      expect(c.read(buying).items.map((i) => i.id), ['conv-1', 'c2', 'c3']);
      expect(c.read(buying).canLoadMore, isFalse);
      expect(messaging.conversationCalls.last, (ConversationRole.buying, 'c2'));
    });

    test('échec du premier chargement, puis Réessayer', () async {
      messaging.conversationsAnswer = const Err(NetworkFailure());
      final c = await start();

      expect(c.read(buying).phase, ListPhase.failed);
      expect(c.read(buying).failure, isA<NetworkFailure>());

      messaging.conversationsAnswer = null;
      await c.read(buying.notifier).refresh();

      expect(c.read(buying).phase, ListPhase.ready);
    });

    test('actualisation ratée : la liste reste, message une fois', () async {
      messaging.conversationsByRole[ConversationRole.buying] = CursorPage(
        items: [sampleConversation()],
      );
      final c = await start();

      messaging.conversationsAnswer = const Err(TimeoutFailure());
      await c.read(buying.notifier).refresh();

      expect(c.read(buying).items, hasLength(1));
      expect(c.read(buying).refreshFailure, isA<TimeoutFailure>());
      c.read(buying.notifier).refreshFailureShown();
      expect(c.read(buying).refreshFailure, isNull);
    });

    test('page suivante en échec : Réessayer', () async {
      messaging.conversationsByRole[ConversationRole.buying] = CursorPage(
        items: [sampleConversation()],
        nextCursor: 'conv-1',
      );
      final c = await start();

      messaging.conversationsAnswer = const Err(NetworkFailure());
      await c.read(buying.notifier).loadMore();
      expect(c.read(buying).loadMoreFailure, isA<NetworkFailure>());
      expect(c.read(buying).canLoadMore, isFalse);

      messaging.conversationsAnswer = null;
      messaging.conversationsByRole[ConversationRole.buying] = CursorPage(
        items: [sampleConversation(id: 'c9')],
      );
      await c.read(buying.notifier).retryLoadMore();
      expect(c.read(buying).items.map((i) => i.id), ['conv-1', 'c9']);
    });

    test('nouveau message (temps réel) : liste relue', () async {
      final c = await start();
      final before = messaging.conversationCalls.length;

      realtime
        ..emit(RealtimeEvent.notification)
        ..emit(RealtimeEvent.message);
      await _settle();

      expect(messaging.conversationCalls.length, before + 1);
      expect(c.read(buying).phase, ListPhase.ready);
    });

    test('discussion ouverte : plus de pastille', () async {
      messaging.conversationsByRole[ConversationRole.buying] = CursorPage(
        items: [
          sampleConversation(unread: 3),
          sampleConversation(id: 'c2'),
        ],
      );
      final c = await start();

      c.read(buying.notifier).markRead('conv-1');

      expect(c.read(buying).unreadCount, 0);
    });
  });

  group('ChatController', () {
    final chat = chatControllerProvider('conv-1');

    Future<ProviderContainer> open() async {
      final c = container()..listen(chat, (_, _) {});
      await _settle();
      return c;
    }

    setUp(() {
      messaging.conversationAnswer = Ok(sampleConversation());
    });

    test('en-tête et messages chargés, compteurs relus', () async {
      messaging.messagesAnswers
        ..clear()
        ..add(
          Ok(
            CursorPage(
              items: [sampleMessage('m2', mine: true), sampleMessage('m1')],
              nextCursor: 'm1',
            ),
          ),
        );
      final unreadBefore = unread.calls;
      final c = await open();

      final state = c.read(chat);
      expect(state.phase, ListPhase.ready);
      expect(state.header?.otherUser.name, 'Aminata K.');
      expect(state.messages.map((m) => m.id), ['m2', 'm1']);
      expect(state.canLoadOlder, isTrue);
      expect(state.canSend, isTrue);
      expect(unread.calls, greaterThan(unreadBefore));
    });

    test('discussion introuvable : échec, puis Réessayer', () async {
      messaging.conversationAnswer = const Err(NotFoundFailure());
      final c = await open();

      expect(c.read(chat).phase, ListPhase.failed);
      expect(c.read(chat).failure, isA<NotFoundFailure>());

      messaging.conversationAnswer = Ok(sampleConversation());
      await c.read(chat.notifier).retry();
      expect(c.read(chat).phase, ListPhase.ready);
    });

    test('messages en échec : échec', () async {
      messaging.messagesAnswers
        ..clear()
        ..add(const Err(ServerFailure(statusCode: 500)));
      final c = await open();

      expect(c.read(chat).failure, isA<ServerFailure>());
    });

    test(
      'messages précédents : ajoutés en haut, échec puis Réessayer',
      () async {
        messaging.messagesAnswers
          ..clear()
          ..addAll([
            Ok(CursorPage(items: [sampleMessage('m3')], nextCursor: 'm3')),
            const Err(NetworkFailure()),
            Ok(CursorPage(items: [sampleMessage('m2'), sampleMessage('m1')])),
          ]);
        final c = await open();

        await c.read(chat.notifier).loadOlder();
        expect(c.read(chat).olderFailure, isA<NetworkFailure>());
        expect(c.read(chat).canLoadOlder, isFalse);

        await c.read(chat.notifier).retryOlder();
        expect(c.read(chat).messages.map((m) => m.id), ['m3', 'm2', 'm1']);
        expect(messaging.messagesCalls.last, 'm3');
        expect(c.read(chat).canLoadOlder, isFalse);
      },
    );

    test('envoi : affiché tout de suite, puis confirmé', () async {
      final c = await open();

      final sending = c.read(chat.notifier).send('  Bonjour  ');
      expect(c.read(chat).pending.single.text, 'Bonjour');
      await sending;

      expect(c.read(chat).pending, isEmpty);
      expect(c.read(chat).messages.first.text, 'Bonjour');
      expect(messaging.sentInConversation.single, ('conv-1', 'Bonjour'));
    });

    test('envoi vide : ignoré', () async {
      final c = await open();

      await c.read(chat.notifier).send('   ');

      expect(c.read(chat).pending, isEmpty);
      expect(messaging.sentInConversation, isEmpty);
    });

    test('envoi en échec : « non envoyé », nouvel essai, retrait', () async {
      messaging.sendAnswer = const Err(NetworkFailure());
      final c = await open();

      await c.read(chat.notifier).send('Bonjour');
      final failed = c.read(chat).pending.single;
      expect(failed.failed, isTrue);
      expect(c.read(chat).sendFailure, isA<NetworkFailure>());
      c.read(chat.notifier).sendFailureShown();
      expect(c.read(chat).sendFailure, isNull);

      messaging.sendAnswer = null;
      await c.read(chat.notifier).resend(failed.localId);
      expect(c.read(chat).pending, isEmpty);
      expect(c.read(chat).messages.first.text, 'Bonjour');

      messaging.sendAnswer = const Err(NetworkFailure());
      await c.read(chat.notifier).send('Encore');
      c.read(chat.notifier).discard(c.read(chat).pending.single.localId);
      expect(c.read(chat).pending, isEmpty);

      // Un message déjà parti ou inconnu : rien à refaire.
      await c.read(chat.notifier).resend(999);
      expect(messaging.sentInConversation, hasLength(3));
    });

    test('compte suspendu : envoi impossible', () async {
      messaging.conversationAnswer = Ok(sampleConversation(canReceive: false));
      final c = await open();

      expect(c.read(chat).canSend, isFalse);
      await c.read(chat.notifier).send('Bonjour');
      expect(messaging.sentInConversation, isEmpty);
    });

    test('nouveau message (temps réel) : ajouté, « Vu » mis à jour', () async {
      final sent = sampleMessage('m1', mine: true);
      messaging.messagesAnswers
        ..clear()
        ..addAll([
          Ok(CursorPage(items: [sent])),
          Ok(
            CursorPage(
              items: [
                sampleMessage('m2'),
                ChatMessage(
                  id: 'm1',
                  text: sent.text,
                  isMine: true,
                  sentAt: sent.sentAt,
                  readAt: DateTime.now(),
                ),
              ],
            ),
          ),
        ]);
      final c = await open();

      realtime.emit(RealtimeEvent.message);
      await _settle();

      final messages = c.read(chat).messages;
      expect(messages.map((m) => m.id), ['m2', 'm1']);
      expect(messages.last.readAt, isNotNull);
    });
  });
}
