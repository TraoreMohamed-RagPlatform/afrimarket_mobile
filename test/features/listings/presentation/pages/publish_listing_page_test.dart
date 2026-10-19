import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/platform/photo_picker.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_theme.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/presentation/pages/publish_listing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_listings_repository.dart';
import '../../../../helpers/fake_publish.dart';
import '../../../../helpers/l10n.dart';

const _bike = ListingCategory(
  id: 'c-articles',
  name: 'Articles',
  slug: 'articles',
  icon: 'shoppingBag',
);

void main() {
  late FakeListingsRepository listings;
  late FakeListingPublisher publisher;
  late FakePhotoPicker picker;

  setUp(() {
    listings = FakeListingsRepository(categories: const Ok([_bike]))
      ..locations = const Ok(sampleLocations);
    publisher = FakeListingPublisher();
    picker = FakePhotoPicker();
  });

  /// Ouvre « Publier » par-dessus un accueil factice (retour possible).
  Future<GoRouter> pump(
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
          builder: (context, state) => const Scaffold(body: Text('ACCUEIL')),
        ),
        GoRoute(
          path: AppRoutes.publish,
          builder: (context, state) => const PublishListingPage(),
        ),
        GoRoute(
          path: AppRoutes.listingPattern,
          builder: (context, state) =>
              Scaffold(body: Text('ANNONCE ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer(
      overrides: [
        ...listingsOverrides(listings),
        ...publishOverrides(publisher: publisher, picker: picker),
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
    unawaited(router.push(AppRoutes.publish));
    await tester.pumpAndSettle();
    return router;
  }

  Finder scrollable() => find.byType(Scrollable).first;

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollable());
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openPhotoSources(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('publish-add-photos')));
    await tester.pumpAndSettle();
  }

  Future<void> addGalleryPhotos(WidgetTester tester) async {
    await openPhotoSources(tester);
    await tester.tap(find.byIcon(AppIcons.images));
    await tester.pumpAndSettle();
  }

  /// Remplit toute l'annonce : 2 photos, « Vélo de ville », 900 DH,
  /// Articles, Maârif, bon état.
  Future<void> fillAll(WidgetTester tester) async {
    await addGalleryPhotos(tester);
    await tester.enterText(
      find.byKey(const Key('publish-title')),
      'Vélo de ville',
    );
    await tester.enterText(find.byKey(const Key('publish-price')), '900');
    await tapVisible(tester, find.byKey(const Key('publish-category')));
    await tester.tap(find.textContaining('Articles'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('publish-district')));
    await tester.tap(find.text('Maârif'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(fr.conditionGood));
    final description = find.byKey(const Key('publish-description'));
    await tester.scrollUntilVisible(description, 200, scrollable: scrollable());
    await tester.enterText(description, 'Freins neufs, pneus en bon état.');
    await tester.pumpAndSettle();
  }

  Future<void> tapPublish(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('publish-submit')));
    await tester.pumpAndSettle();
  }

  group('Formulaire', () {
    testWidgets('une seule page : photos, champs et « Publier »', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text(fr.publishTitle), findsOneWidget);
      expect(find.text(fr.publishPhotosTitle), findsOneWidget);
      expect(find.text(fr.publishPhotosCount(0, 10)), findsOneWidget);
      expect(find.text(fr.publishFieldTitle), findsOneWidget);
      expect(find.text(fr.publishFieldPrice), findsOneWidget);
      expect(find.text(fr.publishSubmit), findsOneWidget);
    });

    testWidgets('incomplète : champs signalés, aucun envoi', (tester) async {
      await pump(tester);

      await tapPublish(tester);

      expect(find.text(fr.publishFixProblems), findsOneWidget);
      expect(find.text(fr.publishErrorPhoto), findsOneWidget);
      expect(find.text(fr.publishErrorTitle), findsOneWidget);
      expect(find.text(fr.publishErrorPrice), findsOneWidget);
      expect(publisher.calls, isEmpty);
    });

    testWidgets('aucune erreur affichée avant le premier essai', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byKey(const Key('publish-title')), 'V');
      await tester.pump();

      expect(find.text(fr.publishErrorTitle), findsNothing);
    });
  });

  group('Photos', () {
    testWidgets('galerie : vignettes, la première est principale', (
      tester,
    ) async {
      await pump(tester);

      await addGalleryPhotos(tester);

      expect(find.text(fr.publishPhotosCount(2, 10)), findsOneWidget);
      expect(find.text(fr.publishPhotoMain), findsOneWidget);
      expect(picker.limits, [ListingDraft.maxPhotos]);
    });

    testWidgets('appareil photo', (tester) async {
      await pump(tester);

      await openPhotoSources(tester);
      await tester.tap(find.text(fr.publishTakePhoto));
      await tester.pumpAndSettle();

      expect(find.text(fr.publishPhotosCount(1, 10)), findsOneWidget);
    });

    testWidgets('accès refusé : message', (tester) async {
      picker.gallery = null;
      await pump(tester);

      await addGalleryPhotos(tester);

      expect(find.text(fr.publishPhotosUnavailable), findsOneWidget);
    });

    testWidgets('appareil photo indisponible : message', (tester) async {
      picker.camera = (null, PhotoPickError.unavailable);
      await pump(tester);

      await openPhotoSources(tester);
      await tester.tap(find.text(fr.publishTakePhoto));
      await tester.pumpAndSettle();

      expect(find.text(fr.publishPhotosUnavailable), findsOneWidget);
    });

    testWidgets('ordre des photos envoyé au serveur', (tester) async {
      picker.gallery = const ['/photos/a.jpg', '/photos/b.jpg'];
      await pump(tester);
      await fillAll(tester);

      // « b » devient la photo principale.
      await tester.scrollUntilVisible(
        find.bySemanticsLabel(fr.publishPhotoLabel(2, 2)),
        -200,
        scrollable: scrollable(),
      );
      await tester.tap(find.bySemanticsLabel(fr.publishPhotoLabel(2, 2)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(fr.publishMakeMain));
      await tester.pumpAndSettle();

      await tapPublish(tester);

      expect(publisher.uploadedPhotos.single, const [
        LocalPhoto('/photos/b.jpg'),
        LocalPhoto('/photos/a.jpg'),
      ]);
    });

    testWidgets('retirer une photo', (tester) async {
      await pump(tester);
      await addGalleryPhotos(tester);

      await tester.tap(
        find.bySemanticsLabel(
          '${fr.publishPhotoLabel(1, 2)}, ${fr.publishPhotoMain}',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(fr.publishMakeMain), findsNothing);
      await tester.tap(find.text(fr.publishRemovePhoto));
      await tester.pumpAndSettle();

      expect(find.text(fr.publishPhotosCount(1, 10)), findsOneWidget);
    });
  });

  group('Publication', () {
    testWidgets('complète : publiée, puis ouverture de l’annonce', (
      tester,
    ) async {
      final router = await pump(tester);
      await fillAll(tester);

      await tapPublish(tester);

      expect(publisher.calls, ['create', 'upload:new-1:2', 'publish:new-1']);
      final draft = publisher.drafts.single;
      expect(draft.title, 'Vélo de ville');
      expect(draft.price, 900);
      expect(draft.categoryId, 'c-articles');
      expect(draft.district, 'maarif');
      expect(draft.condition, ListingCondition.good);
      expect(find.text('ANNONCE new-1'), findsOneWidget);
      expect(find.text(fr.publishSuccess), findsOneWidget);
      // Retour : l'accueil, pas le formulaire.
      expect(router.canPop(), isTrue);
    });

    testWidgets('échec : message, la saisie est conservée', (tester) async {
      publisher.uploaded = const Err(NetworkFailure());
      await pump(tester);
      await fillAll(tester);

      await tapPublish(tester);

      expect(find.text(fr.errorNetwork), findsOneWidget);
      expect(publisher.calls.last, 'delete:new-1');
      expect(find.byType(PublishListingPage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('publish-title')),
        -200,
        scrollable: scrollable(),
      );
      expect(find.text('Vélo de ville'), findsOneWidget);
    });

    testWidgets('négociable et remise transmis', (tester) async {
      await pump(tester);
      await fillAll(tester);

      await tapVisible(tester, find.text(fr.publishNegotiable));
      await tapVisible(tester, find.text(fr.deliveryBoth));
      await tapPublish(tester);

      final draft = publisher.drafts.single;
      expect(draft.isNegotiable, isTrue);
      expect(draft.deliveryMode, DeliveryMode.both);
    });
  });

  group('Quitter', () {
    testWidgets('rien saisi : fermeture directe', (tester) async {
      await pump(tester);

      await tester.tap(find.byTooltip(fr.publishCloseTooltip));
      await tester.pumpAndSettle();

      expect(find.text('ACCUEIL'), findsOneWidget);
    });

    testWidgets('saisie en cours : confirmation, puis « Abandonner »', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(find.byKey(const Key('publish-title')), 'Vélo');
      await tester.pump();

      await tester.tap(find.byTooltip(fr.publishCloseTooltip));
      await tester.pumpAndSettle();
      expect(find.text(fr.publishDiscardTitle), findsOneWidget);

      await tester.tap(find.text(fr.publishDiscardCancel));
      await tester.pumpAndSettle();
      expect(find.byType(PublishListingPage), findsOneWidget);

      await tester.tap(find.byTooltip(fr.publishCloseTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(fr.publishDiscardConfirm));
      await tester.pumpAndSettle();

      expect(find.text('ACCUEIL'), findsOneWidget);
    });
  });

  group('Accessibilité', () {
    for (final (name, locale, mode) in [
      ('clair, français', const Locale('fr'), ThemeMode.light),
      ('sombre, arabe', const Locale('ar'), ThemeMode.dark),
    ]) {
      testWidgets('$name : contraste, cibles tactiles, libellés', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(tester, locale: locale, themeMode: mode);

        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }

    testWidgets('texte doublé, arabe, sombre, erreurs : aucun débordement', (
      tester,
    ) async {
      await pump(
        tester,
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
        textScale: 2,
      );
      await addGalleryPhotos(tester);
      await tapPublish(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
