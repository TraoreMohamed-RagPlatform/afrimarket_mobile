import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:afrimarket_mobile/features/listings/presentation/pages/listing_detail_page.dart';
import 'package:afrimarket_mobile/features/profile/presentation/pages/my_profile_page.dart';
import 'package:afrimarket_mobile/features/search/presentation/pages/search_page.dart';
import 'package:afrimarket_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:afrimarket_mobile/features/support/presentation/pages/help_page.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/l10n.dart';

/// Navigation depuis le fil, dans l'app complète (routeur et gardes).
void main() {
  Future<void> openMenuEntry(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip(fr.menuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('toucher une annonce ouvre son détail', (tester) async {
    await pumpAfriMarketApp(
      tester,
      hasSession: false,
      listings: FakeListingsRepository(
        feed: (page, _) => Ok(samplePage(page, count: 2, hasMore: false)),
      ),
    );

    await tester.tap(find.byType(ListingCard).first);
    await tester.pumpAndSettle();

    final detail = tester.widget<ListingDetailPage>(
      find.byType(ListingDetailPage),
    );
    expect(detail.listingId, 'l1');
  });

  testWidgets('le champ de recherche ouvre la recherche', (tester) async {
    await pumpAfriMarketApp(tester, hasSession: false);

    await tester.tap(find.text(fr.searchHint));
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
  });

  testWidgets('visiteur : Paramètres sans compte', (tester) async {
    await pumpAfriMarketApp(tester, hasSession: false);

    await openMenuEntry(tester, fr.settingsTitle);

    expect(find.byType(SettingsPage), findsOneWidget);
    // Une flèche ramène au fil.
    await tester.tap(find.byTooltip('Retour').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsNothing);
    expect(find.text(fr.feedEmptyTitle), findsOneWidget);
  });

  testWidgets('visiteur : Aide sans compte', (tester) async {
    await pumpAfriMarketApp(tester, hasSession: false);

    await openMenuEntry(tester, fr.helpTitle);

    expect(find.byType(HelpPage), findsOneWidget);
  });

  testWidgets('visiteur : « Mon profil » demande une connexion', (
    tester,
  ) async {
    await pumpAfriMarketApp(tester, hasSession: false);

    await tester.tap(find.byTooltip(fr.myProfileTitle));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MyProfilePage), findsNothing);
  });

  testWidgets('connecté : déconnexion depuis « Mon profil », retour au fil', (
    tester,
  ) async {
    final container = await pumpAfriMarketApp(tester, hasSession: true);

    await openMenuEntry(tester, fr.myProfileTitle);
    expect(find.byType(MyProfilePage), findsOneWidget);

    await tester.tap(find.text(fr.logoutTooltip));
    await tester.pumpAndSettle();

    expect(container.read(sessionProvider), SessionStatus.unauthenticated);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text(fr.feedEmptyTitle), findsOneWidget);
  });

  group('Bouton Retour d’Android', () {
    testWidgets('ferme le menu ☰ sans quitter le fil', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: false);
      await tester.tap(find.byTooltip(fr.menuTooltip));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      expect(find.text(fr.feedEmptyTitle), findsOneWidget);
    });

    testWidgets('ferme la liste des catégories', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: false);
      await tester.tap(find.text(fr.categoriesTitle));
      await tester.pumpAndSettle();
      expect(find.text(fr.categoriesAll), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(fr.categoriesAll), findsNothing);
    });

    testWidgets('le menu couvre la barre du bas', (tester) async {
      await pumpAfriMarketApp(tester, hasSession: false);
      await tester.tap(find.byTooltip(fr.menuTooltip));
      await tester.pumpAndSettle();

      // La barre du bas est sous le voile du menu : on ne peut plus la
      // toucher.
      expect(find.text(fr.navMessages).hitTestable(), findsNothing);
    });
  });

  testWidgets('« Vendre » : un visiteur doit se connecter', (tester) async {
    await pumpAfriMarketApp(tester, hasSession: false);

    await tester.tap(find.text(fr.feedChipSell));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
