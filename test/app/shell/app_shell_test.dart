import 'package:afrimarket_mobile/app/shell/app_shell.dart';
import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:afrimarket_mobile/features/inbox/domain/entities/unread_counts.dart';
import 'package:afrimarket_mobile/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_realtime_connection.dart';
import '../../helpers/fake_unread_counts_repository.dart';
import '../../helpers/l10n.dart';

void main() {
  group('Visiteur', () {
    testWidgets('le fil s’affiche avec la barre du bas', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: false);

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text(fr.feedEmptyTitle), findsOneWidget);
    });

    testWidgets('ordre : Accueil, Notifications, Publier, Messages, Favoris', (
      tester,
    ) async {
      await pumpAfriMarketApp(tester, hasSession: false);

      final xs = [
        fr.navHome,
        fr.navNotifications,
        fr.navPublish,
        fr.navMessages,
        fr.navFavorites,
      ].map((label) => tester.getCenter(find.text(label)).dx).toList();
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], greaterThan(xs[i - 1]));
      }
    });

    testWidgets('onglet Favoris : invitation à se connecter', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: false);

      await tester.tap(find.text(fr.navFavorites));
      await tester.pumpAndSettle();

      expect(find.text(fr.signInFavoritesTitle), findsOneWidget);
      expect(find.text(fr.favoritesComingSoon), findsNothing);
    });

    testWidgets('après connexion : retour sur l’onglet Favoris', (
      tester,
    ) async {
      final container = await pumpAfriMarketApp(tester, hasSession: false);

      await tester.tap(find.text(fr.navFavorites));
      await tester.pumpAndSettle();
      await tester.tap(find.text(fr.signInAction));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      container.read(sessionProvider.notifier).markAuthenticated();
      await tester.pumpAndSettle();

      expect(find.text(fr.favoritesComingSoon), findsOneWidget);
    });

    testWidgets('Publier : connexion demandée', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: false);

      await tester.tap(find.text(fr.navPublish));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('Utilisateur connecté', () {
    testWidgets('onglets Messages et Notifications : le contenu', (
      tester,
    ) async {
      await pumpAfriMarketApp(tester, hasSession: true);

      await tester.tap(find.text(fr.navMessages));
      await tester.pumpAndSettle();
      expect(find.text(fr.messagesEmptyBuyingTitle), findsOneWidget);

      await tester.tap(find.text(fr.navNotifications));
      await tester.pumpAndSettle();
      expect(find.text(fr.notificationsEmptyTitle), findsOneWidget);
    });

    testWidgets('Publier : plein écran, sans barre du bas', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: true);

      await tester.tap(find.text(fr.navPublish));
      await tester.pumpAndSettle();

      expect(find.text(fr.publishTitle), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
    });

    testWidgets('session expirée sur un onglet : l’invitation revient', (
      tester,
    ) async {
      final container = await pumpAfriMarketApp(tester, hasSession: true);

      await tester.tap(find.text(fr.navFavorites));
      await tester.pumpAndSettle();
      expect(find.text(fr.favoritesComingSoon), findsOneWidget);

      await container.read(sessionProvider.notifier).logout();
      await tester.pumpAndSettle();

      expect(find.text(fr.signInFavoritesTitle), findsOneWidget);
      expect(find.text(fr.favoritesComingSoon), findsNothing);
    });
  });

  group('Pastilles de non-lus', () {
    late FakeUnreadCountsRepository unread;

    setUp(() {
      unread = FakeUnreadCountsRepository()
        ..answer = const Ok(UnreadCounts(messages: 3, notifications: 120));
    });

    testWidgets('connecté : messages et notifications non lus', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: true, unread: unread);

      expect(find.text('3'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
      expect(
        find.bySemanticsLabel('${fr.navMessages}, ${fr.unreadCount(3)}'),
        findsOneWidget,
      );
    });

    testWidgets('visiteur : aucune pastille, aucun appel', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: false, unread: unread);

      expect(find.text('3'), findsNothing);
      expect(unread.calls, 0);
    });

    testWidgets('changement d’onglet : compteurs relus', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: true, unread: unread);
      final before = unread.calls;

      unread.answer = const Ok(UnreadCounts.zero);
      await tester.tap(find.text(fr.navMessages));
      await tester.pumpAndSettle();

      expect(unread.calls, before + 1);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('toutes les minutes : compteurs relus', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: true, unread: unread);
      final before = unread.calls;

      await tester.pump(AppShell.unreadRefreshInterval);
      await tester.pumpAndSettle();

      expect(unread.calls, before + 1);
    });

    testWidgets('échec : les pastilles restent', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: true, unread: unread);

      unread.answer = const Err(NetworkFailure());
      await tester.tap(find.text(fr.navFavorites));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('déconnexion : les pastilles disparaissent', (tester) async {
      final container = await pumpAfriMarketApp(
        tester,
        hasSession: true,
        unread: unread,
      );

      await container.read(sessionProvider.notifier).logout();
      await tester.pumpAndSettle();

      expect(find.text('3'), findsNothing);
      expect(find.text('99+'), findsNothing);
    });
  });

  group('Temps réel', () {
    late FakeUnreadCountsRepository unread;
    late FakeRealtimeConnection realtime;

    setUp(() {
      unread = FakeUnreadCountsRepository();
      realtime = FakeRealtimeConnection();
    });

    Future<ProviderContainer> pump(
      WidgetTester tester, {
      bool hasSession = true,
    }) => pumpAfriMarketApp(
      tester,
      hasSession: hasSession,
      unread: unread,
      realtime: realtime,
    );

    testWidgets('connecté : connexion avec le jeton d’accès', (tester) async {
      await pump(tester);

      expect(realtime.tokens, ['test-access-token']);
      expect(realtime.connected, isTrue);
    });

    testWidgets('visiteur : aucune connexion', (tester) async {
      await pump(tester, hasSession: false);

      expect(realtime.tokens, isEmpty);
    });

    testWidgets('message reçu : pastille mise à jour tout de suite', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('4'), findsNothing);

      unread.answer = const Ok(UnreadCounts(messages: 4));
      realtime.emit(RealtimeEvent.message);
      await tester.pumpAndSettle();

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('notification reçue : compteurs relus', (tester) async {
      await pump(tester);
      final before = unread.calls;

      realtime.emit(RealtimeEvent.notification);
      await tester.pumpAndSettle();

      expect(unread.calls, before + 1);
    });

    testWidgets('fermée par le serveur : nouvel essai avec un jeton relu', (
      tester,
    ) async {
      await pump(tester);
      final before = unread.calls;

      realtime.close(RealtimeClosure.byServer);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Compteurs relus d'abord (renouvelle le jeton s'il a expiré).
      expect(unread.calls, greaterThan(before));
      expect(realtime.tokens, hasLength(2));
      expect(realtime.connected, isTrue);
    });

    testWidgets('déconnexion : connexion fermée', (tester) async {
      final container = await pump(tester);

      await container.read(sessionProvider.notifier).logout();
      await tester.pumpAndSettle();

      expect(realtime.connected, isFalse);
    });

    testWidgets('arrière-plan : fermée ; retour : rouverte', (tester) async {
      await pump(tester);

      // Transitions réelles d'Android : resumed → inactive → hidden → paused.
      void goTo(List<AppLifecycleState> states) =>
          states.forEach(tester.binding.handleAppLifecycleStateChanged);

      goTo(const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]);
      await tester.pump();
      expect(realtime.connected, isFalse);

      goTo(const [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      await tester.pumpAndSettle();
      expect(realtime.connected, isTrue);
      expect(realtime.tokens, hasLength(2));
    });
  });
}
