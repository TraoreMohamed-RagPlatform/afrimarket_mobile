import 'dart:convert';
import 'dart:typed_data';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/inbox/data/unread_counts_repository_impl.dart';
import 'package:afrimarket_mobile/features/inbox/domain/entities/unread_counts.dart';
import 'package:afrimarket_mobile/features/inbox/presentation/unread_counts_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_unread_counts_repository.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

/// Faux backend : une réponse par adresse.
class _Server implements HttpClientAdapter {
  final answers = <String, (int, Object)>{};
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    final (status, body) = answers[options.path] ?? (404, {'error': 'x'});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('UnreadCountsRepositoryImpl', () {
    late _Server server;
    late UnreadCountsRepositoryImpl repository;

    setUp(() {
      server = _Server();
      repository = UnreadCountsRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'https://api.example.com'))
          ..httpClientAdapter = server,
      );
    });

    test('lit les deux compteurs', () async {
      server.answers
        ..['/api/messages/unread-count'] = (200, {'count': 3})
        ..['/api/notifications/unread-count'] = (200, {'count': 12});

      final result = await repository.fetch();

      expect(
        (result as Ok<UnreadCounts>).value,
        const UnreadCounts(messages: 3, notifications: 12),
      );
      expect(
        server.paths,
        unorderedEquals([
          '/api/messages/unread-count',
          '/api/notifications/unread-count',
        ]),
      );
    });

    test('nombre démesuré : plafonné', () async {
      server.answers
        ..['/api/messages/unread-count'] = (200, {'count': 1000000})
        ..['/api/notifications/unread-count'] = (200, {'count': 0});

      final result = await repository.fetch();

      expect(
        (result as Ok<UnreadCounts>).value.messages,
        UnreadCountsRepositoryImpl.maxCount,
      );
    });

    test('réponse invalide : UnexpectedFailure, jamais de plantage', () async {
      server.answers
        ..['/api/messages/unread-count'] = (200, {'count': -1})
        ..['/api/notifications/unread-count'] = (200, {'count': 'beaucoup'});

      final result = await repository.fetch();

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });

    test('sans connexion (401) : UnauthorizedFailure', () async {
      server.answers
        ..['/api/messages/unread-count'] = (401, {'error': 'x'})
        ..['/api/notifications/unread-count'] = (200, {'count': 1});

      final result = await repository.fetch();

      expect((result as Err).failure, isA<UnauthorizedFailure>());
    });
  });

  group('UnreadCountsController', () {
    late _MockTokenStorage tokens;
    late FakeUnreadCountsRepository repository;
    late ProviderContainer container;

    Future<void> start({required bool hasSession}) async {
      when(tokens.hasTokens).thenAnswer((_) async => Ok<bool>(hasSession));
      container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokens),
          ...unreadOverrides(repository),
        ],
      );
      addTearDown(container.dispose);
      container.listen(unreadCountsProvider, (_, _) {});
      await pumpEventQueue();
    }

    UnreadCounts counts() => container.read(unreadCountsProvider);

    setUp(() {
      tokens = _MockTokenStorage();
      when(tokens.clear).thenAnswer((_) async => const Ok<void>(null));
      when(tokens.readRefreshToken)
          .thenAnswer((_) async => const Ok<String?>(null));
      repository = FakeUnreadCountsRepository()
        ..answer = const Ok(UnreadCounts(messages: 2, notifications: 5));
    });

    test('visiteur : zéro, aucun appel au serveur', () async {
      await start(hasSession: false);

      await container.read(unreadCountsProvider.notifier).refresh();

      expect(counts(), UnreadCounts.zero);
      expect(repository.calls, 0);
    });

    test('connecté : compteurs lus dès la connexion', () async {
      await start(hasSession: true);

      expect(counts(), const UnreadCounts(messages: 2, notifications: 5));
      expect(repository.calls, 1);
    });

    test('actualisation : nouveaux compteurs', () async {
      await start(hasSession: true);

      repository.answer = const Ok(UnreadCounts(messages: 7));
      await container.read(unreadCountsProvider.notifier).refresh();

      expect(counts(), const UnreadCounts(messages: 7));
    });

    test('échec : les derniers compteurs restent affichés', () async {
      await start(hasSession: true);

      repository.answer = const Err(NetworkFailure());
      await container.read(unreadCountsProvider.notifier).refresh();

      expect(counts(), const UnreadCounts(messages: 2, notifications: 5));
    });

    test('déconnexion : retour à zéro', () async {
      await start(hasSession: true);

      await container.read(sessionProvider.notifier).logout();
      await pumpEventQueue();

      expect(counts(), UnreadCounts.zero);
    });
  });
}
