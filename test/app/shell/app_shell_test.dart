import 'package:afrimarket_mobile/app/shell/app_shell.dart';
import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:afrimarket_mobile/features/inbox/domain/entities/unread_counts.dart';
import 'package:afrimarket_mobile/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
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
      expect(find.text(fr.messagesComingSoon), findsOneWidget);

      await tester.tap(find.text(fr.navNotifications));
      await tester.pumpAndSettle();
      expect(find.text(fr.notificationsComingSoon), findsOneWidget);
    });

    testWidgets('Publier : plein écran, sans barre du bas', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: true);

      await tester.tap(find.text(fr.navPublish));
      await tester.pumpAndSettle();

      expect(find.text(fr.publishComingSoon), findsOneWidget);
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
}
