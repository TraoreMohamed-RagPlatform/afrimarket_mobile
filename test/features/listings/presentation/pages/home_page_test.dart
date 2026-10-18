import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/pages/home_page.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_listings_repository.dart';
import '../../../../helpers/l10n.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

const _housing = ListingCategory(id: 'c1', name: 'Logement');

AppConfig _config(Flavor flavor) {
  return AppConfig.fromValues(
    expected: flavor,
    flavorName: flavor.name,
    appName: 'AfriMarket',
    apiBaseUrl: flavor == Flavor.dev
        ? 'http://10.0.2.2:3000'
        : 'https://api.example.com',
    enableNetworkLogs: false,
  );
}

void main() {
  late _MockTokenStorage tokens;
  late FakeListingsRepository repository;

  setUp(() {
    tokens = _MockTokenStorage();
    repository = FakeListingsRepository(categories: const Ok([_housing]));
    when(() => tokens.clear()).thenAnswer((_) async => const Ok<void>(null));
    // Aucun jeton à révoquer : la déconnexion ne fait aucun appel réseau.
    when(() => tokens.readRefreshToken())
        .thenAnswer((_) async => const Ok<String?>(null));
  });

  /// Affiche le fil et attend la fin des chargements.
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Flavor flavor = Flavor.prod,
    bool hasSession = true,
    Locale locale = const Locale('fr'),
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
  }) async {
    when(() => tokens.hasTokens())
        .thenAnswer((_) async => Ok<bool>(hasSession));

    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_config(flavor)),
        tokenStorageProvider.overrideWithValue(tokens),
        ...listingsOverrides(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      MediaQuery(
        // Taille réelle de l'écran de test : seule la taille du texte change.
        data: MediaQueryData.fromView(tester.view)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: UncontrolledProviderScope(
          container: container,
          child: localizedApp(
            const HomePage(),
            locale: locale,
            themeMode: themeMode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('En-tête', () {
    testWidgets('menu, logo, profil, recherche et pastilles', (tester) async {
      await pump(tester);

      expect(find.byTooltip(fr.menuTooltip), findsOneWidget);
      expect(find.bySemanticsLabel('AfriMarket'), findsWidgets);
      expect(find.byTooltip(fr.myProfileTitle), findsOneWidget);
      expect(find.text(fr.searchHint), findsOneWidget);
      expect(find.text(fr.feedChipSell), findsOneWidget);
      expect(find.text(fr.feedChipForYou), findsOneWidget);
      expect(find.text(fr.categoriesTitle), findsOneWidget);
    });
  });

  group('Fil', () {
    testWidgets('grille d’annonces sous « Sélection du jour »', (tester) async {
      repository.feed = (page, _) => Ok(samplePage(page));

      await pump(tester);

      expect(find.text(fr.feedTodaysPicks), findsOneWidget);
      expect(find.byType(ListingCard), findsWidgets);
    });

    testWidgets('badge « Récent » et mention « Vendu »', (tester) async {
      repository.feed = (page, _) => Ok(
        ListingPage(
          items: [
            sampleListing(
              1,
              createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            ),
            sampleListing(2, isSold: true),
          ],
          page: 1,
          hasMore: false,
        ),
      );

      await pump(tester);

      expect(find.text(fr.badgeRecent), findsOneWidget);
      expect(find.text(fr.listingStatusSold), findsOneWidget);
    });

    testWidgets('fil vide : invitation à publier', (tester) async {
      await pump(tester);

      expect(find.text(fr.feedEmptyTitle), findsOneWidget);
      expect(find.text(fr.feedEmptyAction), findsOneWidget);
      expect(find.text(fr.feedTodaysPicks), findsNothing);
    });

    testWidgets('erreur, puis « Réessayer »', (tester) async {
      repository.feed = (_, _) => const Err(NetworkFailure());
      await pump(tester);
      expect(find.text(fr.errorNetwork), findsOneWidget);

      repository.feed = (page, _) => Ok(samplePage(page, hasMore: false));
      await tester.tap(find.text(fr.retry));
      await tester.pumpAndSettle();

      expect(find.byType(ListingCard), findsWidgets);
    });

    testWidgets('défilement : la page suivante est chargée', (tester) async {
      repository.feed = (page, _) => Ok(samplePage(page, hasMore: page < 2));
      await pump(tester);
      expect(repository.feedCalls, [(1, null)]);

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -6000),
        3000,
      );
      await tester.pumpAndSettle();

      expect(repository.feedCalls, contains((2, null)));
    });

    testWidgets('erreur de page suivante : message en bas, puis reprise', (
      tester,
    ) async {
      repository.feed = (page, _) =>
          page == 1 ? Ok(samplePage(1)) : const Err(TimeoutFailure());
      final container = await pump(tester);

      await container.read(feedControllerProvider.notifier).loadMore();
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text(fr.errorTimeout),
        find.byType(CustomScrollView),
        const Offset(0, -500),
      );
      expect(find.text(fr.errorTimeout), findsOneWidget);

      repository.feed = (page, _) => Ok(samplePage(page, hasMore: false));
      await tester.ensureVisible(find.text(fr.retry));
      await tester.pumpAndSettle();
      await tester.tap(find.text(fr.retry));
      await tester.pumpAndSettle();

      expect(find.text(fr.errorTimeout), findsNothing);
      expect(repository.feedCalls.last, (2, null));
    });

    testWidgets('actualisation ratée : les annonces restent, un message', (
      tester,
    ) async {
      repository.feed = (page, _) => Ok(samplePage(page));
      final container = await pump(tester);

      repository.feed = (_, _) => const Err(NetworkFailure());
      await container.read(feedControllerProvider.notifier).refresh();
      await tester.pump();

      expect(find.text(fr.errorNetwork), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(ListingCard), findsWidgets);
    });
  });

  group('Catégories', () {
    testWidgets('choisir une catégorie filtre le fil', (tester) async {
      repository.feed = (page, _) => Ok(samplePage(page, hasMore: false));
      await pump(tester);

      await tester.tap(find.text(fr.categoriesTitle));
      await tester.pumpAndSettle();
      expect(find.text(fr.categoriesAll), findsOneWidget);

      // Nom venu du serveur : affiché via userText() (texte isolé).
      await tester.tap(find.textContaining('Logement'));
      await tester.pumpAndSettle();

      expect(repository.feedCalls.last, (1, 'c1'));
      // La pastille et le titre de section prennent le nom de la catégorie.
      expect(find.textContaining('Logement'), findsNWidgets(2));
    });

    testWidgets('catégorie vide : « Voir toutes les annonces »', (
      tester,
    ) async {
      repository.feed = (page, category) => category == null
          ? Ok(samplePage(page, hasMore: false))
          : const Ok(ListingPage(items: [], page: 1, hasMore: false));
      final container = await pump(tester);

      await container
          .read(feedControllerProvider.notifier)
          .selectCategory(_housing);
      await tester.pumpAndSettle();
      expect(find.text(fr.feedEmptyCategoryTitle), findsOneWidget);

      await tester.tap(find.text(fr.feedShowAll));
      await tester.pumpAndSettle();

      expect(find.byType(ListingCard), findsWidgets);
    });

    testWidgets('catégories indisponibles : erreur et « Réessayer »', (
      tester,
    ) async {
      repository.categories = const Err(NetworkFailure());
      await pump(tester);

      await tester.tap(find.text(fr.categoriesTitle));
      await tester.pumpAndSettle();
      expect(find.text(fr.errorNetwork), findsOneWidget);

      repository.categories = const Ok([_housing]);
      await tester.tap(find.text(fr.retry));
      await tester.pumpAndSettle();

      expect(find.text('Logement'), findsNothing);
      expect(find.textContaining('Logement'), findsOneWidget);
    });
  });

  group('Menu ☰', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip(fr.menuTooltip));
      await tester.pumpAndSettle();
    }

    testWidgets('catégories, profil, paramètres, aide', (tester) async {
      await pump(tester);
      await openMenu(tester);

      expect(find.byType(Drawer), findsOneWidget);
      for (final label in [fr.myProfileTitle, fr.settingsTitle, fr.helpTitle]) {
        expect(
          find.descendant(of: find.byType(Drawer), matching: find.text(label)),
          findsOneWidget,
        );
      }
    });

    testWidgets('« Catégories » ferme le menu et ouvre la liste', (
      tester,
    ) async {
      await pump(tester);
      await openMenu(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text(fr.categoriesTitle),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      expect(find.text(fr.categoriesAll), findsOneWidget);
    });

    testWidgets('connecté : « Se déconnecter » termine la session', (
      tester,
    ) async {
      final container = await pump(tester);
      await openMenu(tester);

      await tester.tap(find.text(fr.logoutTooltip));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider), SessionStatus.unauthenticated);
      verify(() => tokens.clear()).called(1);
    });

    testWidgets('visiteur : « Se connecter » à la place', (tester) async {
      await pump(tester, hasSession: false);
      await openMenu(tester);

      expect(find.text(fr.signInAction), findsOneWidget);
      expect(find.text(fr.logoutTooltip), findsNothing);
    });

    testWidgets('dev : outils de développement dans le menu', (tester) async {
      await pump(tester, flavor: Flavor.dev);
      await openMenu(tester);

      expect(find.text(fr.devDiagnosticsButton), findsOneWidget);
      expect(find.text(fr.devGalleryButton), findsOneWidget);
    });

    testWidgets('prod : aucun outil de développement', (tester) async {
      await pump(tester);
      await openMenu(tester);

      expect(find.text(fr.devToolsSection), findsNothing);
      expect(find.text(fr.devDiagnosticsButton), findsNothing);
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
        repository.feed = (page, _) => Ok(samplePage(page, hasMore: false));
        final handle = tester.ensureSemantics();
        await pump(tester, locale: locale, themeMode: mode);

        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }

    testWidgets('texte doublé, arabe, sombre : aucun débordement', (
      tester,
    ) async {
      repository.feed = (page, _) => Ok(samplePage(page, hasMore: false));

      await pump(
        tester,
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
