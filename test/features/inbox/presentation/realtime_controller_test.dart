import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/inbox/presentation/realtime_controller.dart';
import 'package:afrimarket_mobile/features/inbox/presentation/unread_counts_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_realtime_connection.dart';
import '../../../helpers/fake_unread_counts_repository.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

/// Session fixée par le test (aucune lecture du stockage).
class _Session extends SessionNotifier {
  new(this._initial);

  final SessionStatus _initial;

  @override
  SessionStatus build() => _initial;
}

/// Contrôleur temps réel seul, avec fausse connexion et faux compteurs.
class _Harness {
  final connection = FakeRealtimeConnection();
  final unread = FakeUnreadCountsRepository();
  final tokens = _MockTokenStorage();
  Result<String?> token = const Ok('jeton');
  ProviderContainer? _container;

  ProviderContainer get container => _container!;

  RealtimeController get controller =>
      container.read(realtimeProvider.notifier);

  RealtimeStatus get status => container.read(realtimeProvider);

  /// Crée l'app (session [session]) puis démarre le temps réel.
  Future<void> start(
    WidgetTester tester, {
    SessionStatus session = SessionStatus.authenticated,
  }) async {
    when(tokens.readAccessToken).thenAnswer((_) async => token);
    _container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _Session(session)),
        tokenStorageProvider.overrideWithValue(tokens),
        ...unreadOverrides(unread),
        ...realtimeOverrides(connection),
      ],
    );
    // Compteurs créés d'abord : leur première lecture ne fausse pas les
    // comptes des tests.
    container.read(unreadCountsProvider);
    await tester.pump();
    controller.start();
    await tester.pump();
  }

  /// Laisse passer [duration] (minuteurs) puis les tâches en attente.
  Future<void> wait(WidgetTester tester, Duration duration) async {
    await tester.pump(duration);
    await tester.pump();
  }

  void dispose() => _container?.dispose();
}

/// Test avec un [_Harness] libéré à la fin (aucun minuteur ne reste).
void _realtimeTest(
  String description,
  Future<void> Function(WidgetTester tester, _Harness harness) body,
) {
  testWidgets(description, (tester) async {
    final harness = _Harness();
    try {
      await body(tester, harness);
    } finally {
      harness.dispose();
    }
  });
}

void main() {
  _realtimeTest('connecté : connexion avec le jeton', (tester, h) async {
    await h.start(tester);

    expect(h.connection.tokens, ['jeton']);
    expect(h.status, RealtimeStatus.connecting);
  });

  _realtimeTest('visiteur puis connexion : connexion ouverte', (
    tester,
    h,
  ) async {
    await h.start(tester, session: SessionStatus.unauthenticated);
    expect(h.connection.tokens, isEmpty);

    h.container.read(sessionProvider.notifier).markAuthenticated();
    await tester.pump();

    expect(h.connection.tokens, ['jeton']);
  });

  _realtimeTest('déconnexion : connexion fermée, état off', (tester, h) async {
    await h.start(tester);

    h.container.read(sessionProvider.notifier).markSignedOut();
    await tester.pump();

    expect(h.connection.connected, isFalse);
    expect(h.status, RealtimeStatus.off);
  });

  _realtimeTest('jeton absent : nouvel essai après relecture des compteurs', (
    tester,
    h,
  ) async {
    h.token = const Ok(null);
    await h.start(tester);

    expect(h.connection.tokens, isEmpty);
    expect(h.status, RealtimeStatus.waitingToRetry);

    h.token = const Ok('jeton-neuf');
    final before = h.unread.calls;
    await h.wait(tester, RealtimeController.retryDelays.first);

    expect(h.unread.calls, before + 1);
    expect(h.connection.tokens, ['jeton-neuf']);
  });

  _realtimeTest('jeton illisible ou vide : nouvel essai', (tester, h) async {
    h.token = const Err(NetworkFailure());
    await h.start(tester);
    expect(h.status, RealtimeStatus.waitingToRetry);

    h.token = const Ok('');
    await h.wait(tester, RealtimeController.retryDelays.first);

    expect(h.connection.tokens, isEmpty);
    expect(h.status, RealtimeStatus.waitingToRetry);
  });

  _realtimeTest('fermetures répétées : délais croissants', (tester, h) async {
    await h.start(tester);
    const delays = RealtimeController.retryDelays;

    h.connection.close(RealtimeClosure.network);
    await h.wait(tester, delays[0]);
    expect(h.connection.tokens, hasLength(2));

    h.connection.close(RealtimeClosure.byServer);
    await h.wait(tester, delays[0]);
    expect(h.connection.tokens, hasLength(2));
    expect(h.status, RealtimeStatus.waitingToRetry);

    await h.wait(tester, delays[1] - delays[0]);
    expect(h.connection.tokens, hasLength(3));
  });

  _realtimeTest('événement reçu : les délais repartent du plus court', (
    tester,
    h,
  ) async {
    await h.start(tester);
    const delays = RealtimeController.retryDelays;

    h.connection.close(RealtimeClosure.network);
    await h.wait(tester, delays[0]);
    h.connection.emit(RealtimeEvent.message);
    await tester.pump();
    h.connection.close(RealtimeClosure.network);
    await h.wait(tester, delays[0]);

    expect(h.connection.tokens, hasLength(3));
  });

  _realtimeTest('en pause : fermeture ignorée, aucun nouvel essai', (
    tester,
    h,
  ) async {
    await h.start(tester);

    h.controller
      ..pause()
      ..pause();
    h.connection.close(RealtimeClosure.byServer);
    await h.wait(tester, RealtimeController.retryDelays.last);

    expect(h.connection.tokens, hasLength(1));
    expect(h.status, RealtimeStatus.off);
  });

  _realtimeTest('démarré deux fois : un seul abonnement', (tester, h) async {
    await h.start(tester);
    h.controller.start();
    final before = h.unread.calls;

    h.connection.emit(RealtimeEvent.notification);
    await tester.pump();

    expect(h.unread.calls, before + 1);
    expect(h.connection.tokens, hasLength(1));
  });

  _realtimeTest('arrêté : plus aucun événement pris en compte', (
    tester,
    h,
  ) async {
    await h.start(tester);
    h.controller.stop();
    final before = h.unread.calls;

    h.connection
      ..emit(RealtimeEvent.message)
      ..close(RealtimeClosure.byServer);
    await h.wait(tester, RealtimeController.retryDelays.last);

    expect(h.unread.calls, before);
    expect(h.connection.connected, isFalse);
    expect(h.connection.tokens, hasLength(1));
  });
}
