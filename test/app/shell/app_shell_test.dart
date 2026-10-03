import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/l10n.dart';

void main() {
  group('Visiteur', () {
    testWidgets('le fil s’affiche avec la barre du bas', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: false);

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text(fr.homeComingSoon), findsOneWidget);
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
      expect(find.text(fr.loginComingSoon), findsOneWidget);

      container.read(sessionProvider.notifier).markAuthenticated();
      await tester.pumpAndSettle();

      expect(find.text(fr.favoritesComingSoon), findsOneWidget);
    });

    testWidgets('Publier : connexion demandée', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: false);

      await tester.tap(find.text(fr.navPublish));
      await tester.pumpAndSettle();

      expect(find.text(fr.loginComingSoon), findsOneWidget);
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
}
