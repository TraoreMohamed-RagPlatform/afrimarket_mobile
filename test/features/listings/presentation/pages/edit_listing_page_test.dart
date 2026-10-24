import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_theme.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_changes.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/presentation/pages/edit_listing_page.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_listings_repository.dart';
import '../../../../helpers/fake_publish.dart';
import '../../../../helpers/l10n.dart';

/// Adresses non web : vignettes de remplacement (pas de réseau en test).
const _p1 = RemotePhoto(id: 'p1', url: 'test://p1');
const _p2 = RemotePhoto(id: 'p2', url: 'test://p2');
const _mobilier = ListingCategory(id: 'c1', name: 'Mobilier', icon: 'armchair');

ListingDetail _mine({bool isSold = false, bool isOwner = true}) => sampleDetail(
  isOwner: isOwner,
  isSold: isSold,
  photos: const [_p1, _p2],
  category: _mobilier,
);

void main() {
  late FakeListingsRepository listings;
  late FakeListingPublisher publisher;

  setUp(() {
    listings = FakeListingsRepository(categories: const Ok([_mobilier]))
      ..detail = Ok(_mine())
      ..locations = const Ok(sampleLocations);
    publisher = FakeListingPublisher();
  });

  /// Ouvre « Modifier » par-dessus l'annonce (factice), elle-même
  /// par-dessus le fil.
  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('fr'),
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('FIL')),
        ),
        GoRoute(
          path: AppRoutes.listingPattern,
          builder: (context, state) =>
              Scaffold(body: Text('ANNONCE ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: AppRoutes.editListingPattern,
          builder: (context, state) =>
              EditListingPage(listingId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer(
      overrides: [
        ...listingsOverrides(listings),
        ...publishOverrides(publisher: publisher),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.view)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(AppRoutes.listing('listing-1')));
    await tester.pumpAndSettle();
    unawaited(router.push(AppRoutes.editListing('listing-1')));
    await tester.pumpAndSettle();
  }

  Finder saveButton() => find.byKey(const Key('edit-save'));

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(saveButton()).onPressed != null;

  Future<void> close(WidgetTester tester) async {
    await tester.tap(find.byTooltip(fr.publishCloseTooltip));
    await tester.pumpAndSettle();
  }

  testWidgets('formulaire rempli avec l’annonce, rien à enregistrer', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(fr.editListingTitle), findsOneWidget);
    expect(find.text('Canapé 3 places, tissu gris'), findsOneWidget);
    expect(find.text('1200'), findsOneWidget);
    expect(find.text(userText('Mobilier')), findsOneWidget);
    expect(find.text('Maârif, Casablanca'), findsOneWidget);
    expect(find.text(fr.publishPhotoMain), findsOneWidget);
    expect(find.text(fr.publishPhotosCount(2, 10)), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('prix changé : enregistré, retour à l’annonce', (tester) async {
    await pump(tester);

    await tester.enterText(find.byKey(const Key('publish-price')), '900');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);

    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(publisher.changes.single, const ListingChanges(price: 900));
    expect(find.text('ANNONCE listing-1'), findsOneWidget);
    expect(find.text(fr.editListingSaved), findsOneWidget);
  });

  testWidgets('photo retirée puis enregistrée', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel(fr.publishPhotoLabel(2, 2)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(fr.publishRemovePhoto));
    await tester.pumpAndSettle();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(publisher.calls, ['deletePhoto:p2']);
  });

  testWidgets('quitter sans changement : directement', (tester) async {
    await pump(tester);

    await close(tester);

    expect(find.text('ANNONCE listing-1'), findsOneWidget);
  });

  testWidgets('quitter avec des changements : confirmation', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('publish-title')), 'Canapé');
    await tester.pump();

    await close(tester);
    expect(find.text(fr.editDiscardTitle), findsOneWidget);
    await tester.tap(find.text(fr.editDiscardCancel));
    await tester.pumpAndSettle();
    expect(find.text(fr.editListingTitle), findsOneWidget);

    await close(tester);
    await tester.tap(find.text(fr.publishDiscardConfirm));
    await tester.pumpAndSettle();

    expect(find.text('ANNONCE listing-1'), findsOneWidget);
    expect(publisher.calls, isEmpty);
  });

  testWidgets('titre trop court : signalé, rien n’est envoyé', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('publish-title')), 'C');
    await tester.pump();

    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(find.text(fr.publishErrorTitle), findsOneWidget);
    expect(find.text(fr.publishFixProblems), findsOneWidget);
    expect(publisher.calls, isEmpty);
  });

  testWidgets('échec : message, la saisie reste', (tester) async {
    publisher.updated = const Err(NetworkFailure());
    await pump(tester);
    await tester.enterText(find.byKey(const Key('publish-price')), '900');
    await tester.pump();

    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(find.text(fr.errorNetwork), findsOneWidget);
    expect(find.text('900'), findsOneWidget);
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('à moitié enregistrée : message dédié, annonce relue', (
    tester,
  ) async {
    publisher.reordered = const Err(ServerFailure());
    await pump(tester);
    await tester.enterText(find.byKey(const Key('publish-price')), '900');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(fr.publishPhotoLabel(2, 2)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(fr.publishMakeMain));
    await tester.pumpAndSettle();

    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(find.text(fr.editListingPartial), findsOneWidget);
    // Relue depuis le serveur (faux : inchangée).
    expect(find.text('1200'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('vendue : plus modifiable', (tester) async {
    listings.detail = Ok(_mine(isSold: true));
    await pump(tester);

    expect(find.text(fr.editListingSold), findsOneWidget);
    expect(saveButton(), findsNothing);
  });

  testWidgets('annonce d’un autre : indisponible', (tester) async {
    listings.detail = Ok(_mine(isOwner: false));
    await pump(tester);

    expect(find.text(fr.editListingUnavailable), findsOneWidget);
  });

  testWidgets('erreur de lecture, puis « Réessayer »', (tester) async {
    listings.detail = const Err(NetworkFailure());
    await pump(tester);

    listings.detail = Ok(_mine());
    await tester.tap(find.text(fr.retry));
    await tester.pumpAndSettle();

    expect(find.text('Canapé 3 places, tissu gris'), findsOneWidget);
  });

  testWidgets('mode sombre, arabe (RTL), texte ×2 : sans débordement', (
    tester,
  ) async {
    await pump(
      tester,
      locale: const Locale('ar'),
      themeMode: ThemeMode.dark,
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(find.text(ar.editListingTitle), findsOneWidget);
    expect(find.text(ar.editListingSave), findsOneWidget);
  });
}
