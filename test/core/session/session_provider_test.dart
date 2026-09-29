import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/session_expiry.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

void main() {
  late _MockTokenStorage tokens;

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(tokens)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Attend la fin de la vérification de démarrage, en écoutant l'état.
  Future<SessionStatus> settled(ProviderContainer container) {
    final completer = Completer<SessionStatus>();
    final subscription = container.listen<SessionStatus>(sessionProvider, (
      previous,
      next,
    ) {
      if (next != SessionStatus.unknown && !completer.isCompleted) {
        completer.complete(next);
      }
    }, fireImmediately: true);
    return completer.future.whenComplete(subscription.close);
  }

  setUp(() {
    tokens = _MockTokenStorage();
    when(() => tokens.clear()).thenAnswer((_) async => const Ok<void>(null));
  });

  group('SessionNotifier', () {
    test('démarre à unknown', () {
      when(() => tokens.hasTokens())
          .thenAnswer((_) => Completer<Result<bool>>().future);

      final container = createContainer();

      expect(container.read(sessionProvider), SessionStatus.unknown);
    });

    test('authenticated si des tokens existent', () async {
      when(() => tokens.hasTokens())
          .thenAnswer((_) async => const Ok<bool>(true));

      final container = createContainer();

      expect(await settled(container), SessionStatus.authenticated);
    });

    test('unauthenticated sans tokens', () async {
      when(() => tokens.hasTokens())
          .thenAnswer((_) async => const Ok<bool>(false));

      final container = createContainer();

      expect(await settled(container), SessionStatus.unauthenticated);
    });

    test('fermé par défaut : erreur de stockage = déconnecté', () async {
      when(() => tokens.hasTokens())
          .thenAnswer((_) async => const Err<bool>(StorageFailure()));

      final container = createContainer();

      expect(await settled(container), SessionStatus.unauthenticated);
    });

    test('une session expirée déconnecte automatiquement', () async {
      when(() => tokens.hasTokens())
          .thenAnswer((_) async => const Ok<bool>(true));
      final container = createContainer();
      await settled(container);

      container.read(sessionExpiryProvider.notifier).notify();

      expect(container.read(sessionProvider), SessionStatus.unauthenticated);
    });

    test('markAuthenticated connecte l’utilisateur', () async {
      when(() => tokens.hasTokens())
          .thenAnswer((_) async => const Ok<bool>(false));
      final container = createContainer();
      await settled(container);

      container.read(sessionProvider.notifier).markAuthenticated();

      expect(container.read(sessionProvider), SessionStatus.authenticated);
    });

    test('la vérification n’écrase pas une connexion en cours', () async {
      final pending = Completer<Result<bool>>();
      when(() => tokens.hasTokens()).thenAnswer((_) => pending.future);
      final container = createContainer()..read(sessionProvider);

      container.read(sessionProvider.notifier).markAuthenticated();
      pending.complete(const Ok<bool>(false));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(sessionProvider), SessionStatus.authenticated);
    });

    test('logout déconnecte et efface les tokens', () async {
      when(() => tokens.hasTokens())
          .thenAnswer((_) async => const Ok<bool>(true));
      final container = createContainer();
      await settled(container);

      await container.read(sessionProvider.notifier).logout();

      expect(container.read(sessionProvider), SessionStatus.unauthenticated);
      verify(() => tokens.clear()).called(1);
    });
  });
}
