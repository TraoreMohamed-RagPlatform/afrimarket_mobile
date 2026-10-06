import 'package:afrimarket_mobile/app/dev/gallery_page.dart';
import 'package:afrimarket_mobile/app/router/app_router.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/l10n.dart';

/// Agrandit l'écran de test pour que TOUTE la galerie soit affichée
/// (les contrôles d'accessibilité ne portent que sur ce qui est visible).
void _tallScreen(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(420, 14000);
  addTearDown(tester.view.reset);
}

// La galerie contient des animations continues (squelettes) :
// utiliser pump(), jamais pumpAndSettle().
Future<void> _pumpGallery(
  WidgetTester tester, {
  bool dark = false,
  Locale locale = const Locale('fr'),
  bool largeText = false,
}) async {
  _tallScreen(tester);
  await tester.pumpWidget(
    localizedApp(
      GalleryPage(
        initialDark: dark,
        initialLocale: locale,
        initialLargeText: largeText,
      ),
    ),
  );
  await tester.pump();
}

/// Les 3 contrôles d'accessibilité officiels de Flutter.
Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  group('Accessibilité de tout le design system', () {
    for (final (name, dark, locale) in [
      ('clair, français', false, const Locale('fr')),
      ('sombre, français', true, const Locale('fr')),
      ('clair, arabe', false, const Locale('ar')),
    ]) {
      testWidgets(name, (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpGallery(tester, dark: dark, locale: locale);

        await _expectAccessible(tester);
        semantics.dispose();
      });
    }
  });

  testWidgets('texte doublé : aucun débordement', (tester) async {
    // Toute erreur de mise en page fait échouer le test, avec son détail.
    await _pumpGallery(tester, largeText: true);
  });

  testWidgets('les commandes changent la langue de la galerie', (tester) async {
    final ar = lookupAppLocalizations(const Locale('ar'));
    await _pumpGallery(tester);
    expect(find.text(fr.searchHint), findsOneWidget);

    await tester.tap(find.text('AR'));
    await tester.pump();

    final hint = find.text(ar.searchHint);
    expect(hint, findsOneWidget);
    expect(Directionality.of(tester.element(hint)), TextDirection.rtl);
  });

  group('Route de la galerie', () {
    testWidgets('dev : la galerie existe', (tester) async {
      final container = await pumpAfriMarketApp(tester, hasSession: false);

      container.read(appRouterProvider).go(AppRoutes.gallery);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GalleryPage), findsOneWidget);
    });

    testWidgets('prod : la galerie n’existe pas', (tester) async {
      final container = await pumpAfriMarketApp(
        tester,
        hasSession: false,
        flavor: Flavor.prod,
      );

      container.read(appRouterProvider).go(AppRoutes.gallery);
      await tester.pumpAndSettle();

      expect(find.byType(GalleryPage), findsNothing);
      expect(find.text(fr.notFoundMessage), findsOneWidget);
    });
  });
}
