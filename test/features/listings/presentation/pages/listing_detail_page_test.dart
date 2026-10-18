import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/platform/external_actions.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/core/theme/app_theme.dart';
import 'package:afrimarket_mobile/features/favorites/favorites_providers.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/report_reason.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/seller_contact.dart';
import 'package:afrimarket_mobile/features/listings/presentation/pages/listing_detail_page.dart';
import 'package:afrimarket_mobile/features/messaging/messaging_providers.dart';
import 'package:afrimarket_mobile/shared/formatters/price_formatter.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_detail_services.dart';
import '../../../../helpers/fake_listings_repository.dart';
import '../../../../helpers/l10n.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

const _phone = '+212612345678';

/// Prix tels qu'affichés (séparateur de milliers de la langue).
final String _price = formatPrice(1200, fr);
final String _oldPrice = formatPrice(1500, fr);

void main() {
  late _MockTokenStorage tokens;
  late FakeListingsRepository listings;
  late FakeFavoritesRepository favorites;
  late FakeMessagingRepository messaging;
  late FakeExternalActions actions;

  setUp(() {
    tokens = _MockTokenStorage();
    listings = FakeListingsRepository()
      ..detail = Ok(sampleDetail())
      ..locations = const Ok(sampleLocations)
      ..contact = const Ok(SellerContact(phone: _phone, whatsapp: true));
    favorites = FakeFavoritesRepository();
    messaging = FakeMessagingRepository();
    actions = FakeExternalActions();
  });

  /// Ouvre `/listings/listing-1` dans un vrai routeur (retour, connexion,
  /// autres annonces) et attend la fin des chargements.
  Future<GoRouter> pump(
    WidgetTester tester, {
    bool hasSession = true,
    Locale locale = const Locale('fr'),
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
  }) async {
    when(tokens.hasTokens).thenAnswer((_) async => Ok<bool>(hasSession));
    // Écran de téléphone (390 × 844, comme la maquette) : la photo carrée
    // laisse voir le titre, le prix, le message et les actions.
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.listing('listing-1'),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Text('FIL'),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => Text('CONNEXION ${state.uri}'),
        ),
        GoRoute(
          path: AppRoutes.listingPattern,
          builder: (context, state) =>
              ListingDetailPage(listingId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(
            expected: Flavor.prod,
            flavorName: Flavor.prod.name,
            appName: 'AfriMarket',
            apiBaseUrl: 'https://api.example.com',
            enableNetworkLogs: false,
          ),
        ),
        tokenStorageProvider.overrideWithValue(tokens),
        ...listingsOverrides(listings),
        favoritesRepositoryProvider.overrideWithValue(favorites),
        messagingRepositoryProvider.overrideWithValue(messaging),
        externalActionsProvider.overrideWithValue(actions),
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
    return router;
  }

  Finder scrollable() => find.byType(CustomScrollView);

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(finder, scrollable(), const Offset(0, -300));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).first;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('Contenu', () {
    testWidgets('titre, prix, ancien prix, « Négociable », date et lieu', (
      tester,
    ) async {
      await pump(tester);

      expect(
        find.textContaining('Canapé 3 places, tissu gris'),
        findsOneWidget,
      );
      expect(find.text(_price), findsOneWidget);
      expect(find.text(_oldPrice), findsOneWidget);
      expect(find.text(fr.badgeNegotiable), findsOneWidget);
      expect(
        find.text('${fr.listingPublishedHours(2)} · Maârif, Casablanca'),
        findsOneWidget,
      );
    });

    testWidgets('message au vendeur et actions', (tester) async {
      await pump(tester);

      expect(find.text(fr.listingMessageTitle), findsOneWidget);
      expect(find.text(fr.listingMessageDefault), findsOneWidget);
      for (final label in [
        fr.listingActionWhatsapp,
        fr.listingActionCall,
        fr.listingActionSave,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text(fr.listingActionShare), findsOneWidget);
    });

    testWidgets('détails, vendeur, conseils de sécurité', (tester) async {
      await pump(tester);

      await scrollTo(tester, find.text(fr.listingSafetyTitle));

      expect(find.text(fr.conditionGood), findsOneWidget);
      expect(find.textContaining('Mobilier'), findsOneWidget);
      expect(find.text(fr.deliveryPickup), findsOneWidget);
      expect(find.textContaining('Aminata K.'), findsWidgets);
      expect(find.text(fr.sellerMemberSince('2025')), findsOneWidget);
      expect(find.text(fr.sellerResponseWithinHour), findsOneWidget);
      expect(find.text(fr.listingReportAction), findsOneWidget);
    });

    testWidgets('vendeur sans avis : « Nouveau vendeur »', (tester) async {
      listings.detail = Ok(
        sampleDetail(
          seller: sampleSeller(ratingCount: 0, responseTimeMinutes: null),
        ),
      );
      await pump(tester);

      await scrollTo(tester, find.text(fr.sellerNew));

      expect(find.text(fr.sellerNew), findsOneWidget);
      expect(find.text(fr.sellerResponseWithinHour), findsNothing);
    });

    testWidgets('vendue : badge, ni message ni appel', (tester) async {
      listings.detail = Ok(sampleDetail(isSold: true));
      await pump(tester);

      expect(find.text(fr.listingStatusSold), findsOneWidget);
      expect(find.text(fr.badgeNegotiable), findsNothing);
      expect(find.text(fr.listingMessageTitle), findsNothing);
      expect(find.text(fr.listingActionCall), findsNothing);
      expect(find.text(fr.listingActionWhatsapp), findsNothing);
      expect(find.text(fr.listingActionSave), findsOneWidget);
    });

    testWidgets('numéro non partagé : ni WhatsApp ni Appeler', (tester) async {
      listings.detail = Ok(
        sampleDetail(seller: sampleSeller(canCall: false, canWhatsapp: false)),
      );
      await pump(tester);

      expect(find.text(fr.listingActionCall), findsNothing);
      expect(find.text(fr.listingActionWhatsapp), findsNothing);
    });

    testWidgets('longue description : « Voir plus » puis « Voir moins »', (
      tester,
    ) async {
      listings.detail = Ok(
        sampleDetail(description: List.filled(40, 'Très bon état.').join(' ')),
      );
      await pump(tester);

      await scrollTo(tester, find.text(fr.listingSeeMore));
      await tester.tap(find.text(fr.listingSeeMore));
      await tester.pumpAndSettle();

      expect(find.text(fr.listingSeeLess), findsOneWidget);
    });
  });

  group('États', () {
    testWidgets('introuvable : invitation à voir d’autres annonces', (
      tester,
    ) async {
      listings.detail = const Err(NotFoundFailure());
      await pump(tester);

      expect(find.text(fr.listingNotFoundTitle), findsOneWidget);

      await tester.tap(find.text(fr.listingNotFoundAction));
      await tester.pumpAndSettle();
      expect(find.text('FIL'), findsOneWidget);
    });

    testWidgets('erreur réseau, puis « Réessayer »', (tester) async {
      listings.detail = const Err(NetworkFailure());
      await pump(tester);
      expect(find.text(fr.errorNetwork), findsOneWidget);

      listings.detail = Ok(sampleDetail());
      await tester.tap(find.text(fr.retry));
      await tester.pumpAndSettle();

      expect(find.text(_price), findsOneWidget);
    });

    testWidgets('retour sans page précédente : le fil', (tester) async {
      await pump(tester);

      await tester.tap(find.byTooltip(fr.listingBackTooltip));
      await tester.pumpAndSettle();

      expect(find.text('FIL'), findsOneWidget);
    });
  });

  group('Visiteur : connexion, puis retour à l’annonce', () {
    for (final label in [
      fr.listingMessageSend,
      fr.listingActionSave,
      fr.listingActionCall,
    ]) {
      testWidgets('« $label »', (tester) async {
        await pump(tester, hasSession: false);

        await tapText(tester, label);

        expect(
          find.text('CONNEXION /login?from=%2Flistings%2Flisting-1'),
          findsOneWidget,
        );
        expect(messaging.sent, isEmpty);
        expect(favorites.saved, isEmpty);
        expect(listings.contactCalls, isEmpty);
      });
    }
  });

  group('Connecté', () {
    testWidgets('envoyer le message proposé', (tester) async {
      await pump(tester);

      await tapText(tester, fr.listingMessageSend);

      expect(messaging.sent, [('seller-1', fr.listingMessageDefault)]);
      expect(find.text(fr.listingMessageSent), findsOneWidget);
    });

    testWidgets('message vide : rien n’est envoyé', (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tapText(tester, fr.listingMessageSend);

      expect(messaging.sent, isEmpty);
      expect(find.text(fr.listingMessageEmpty), findsOneWidget);
    });

    testWidgets('sa propre annonce : message clair', (tester) async {
      messaging.answer = const Err(ValidationFailure());
      await pump(tester);

      await tapText(tester, fr.listingMessageSend);

      expect(find.text(fr.listingOwnListingError), findsOneWidget);
    });

    testWidgets('appeler : composeur avec le numéro', (tester) async {
      await pump(tester);

      await tapText(tester, fr.listingActionCall);

      expect(listings.contactCalls, ['listing-1']);
      expect(actions.dialed, [_phone]);
    });

    testWidgets('WhatsApp : discussion avec un message prérempli', (
      tester,
    ) async {
      await pump(tester);

      await tapText(tester, fr.listingActionWhatsapp);

      final (number, message) = actions.whatsapp.single;
      expect(number, '212612345678');
      expect(message, contains('Canapé 3 places, tissu gris'));
    });

    testWidgets('WhatsApp absent : message', (tester) async {
      actions.canOpen = false;
      await pump(tester);

      await tapText(tester, fr.listingActionWhatsapp);

      expect(find.text(fr.listingWhatsappFailed), findsOneWidget);
    });

    testWidgets('numéro retiré entre-temps : message', (tester) async {
      listings.contact = const Err(NotFoundFailure());
      await pump(tester);

      await tapText(tester, fr.listingActionCall);

      expect(actions.dialed, isEmpty);
      expect(find.text(fr.listingContactUnavailable), findsOneWidget);
    });

    testWidgets('enregistrer, puis retirer', (tester) async {
      await pump(tester);

      await tapText(tester, fr.listingActionSave);
      expect(favorites.saved, {'listing-1'});
      expect(find.text(fr.listingActionSaved), findsOneWidget);
      expect(find.text(fr.listingSavedMessage), findsOneWidget);

      await tapText(tester, fr.listingActionSaved);
      expect(favorites.saved, isEmpty);
      expect(find.text(fr.listingActionSave), findsOneWidget);
    });

    testWidgets('échec de l’enregistrement : état rétabli', (tester) async {
      favorites.answer = const Err(NetworkFailure());
      await pump(tester);

      await tapText(tester, fr.listingActionSave);

      expect(find.text(fr.listingActionSave), findsOneWidget);
      expect(find.text(fr.errorNetwork), findsOneWidget);
    });

    testWidgets('déjà enregistrée : « Enregistrée » dès l’ouverture', (
      tester,
    ) async {
      favorites.saved.add('listing-1');
      await pump(tester);

      expect(find.text(fr.listingActionSaved), findsOneWidget);
    });

    testWidgets('partager : titre et prix', (tester) async {
      await pump(tester);

      await tester.tap(find.byTooltip(fr.listingActionShare));
      await tester.pumpAndSettle();

      expect(actions.shared.single, contains('Canapé 3 places, tissu gris'));
      expect(actions.shared.single, contains(_price));
    });

    testWidgets('signaler : motif, détail, confirmation', (tester) async {
      await pump(tester);

      await scrollTo(tester, find.text(fr.listingReportAction));
      await tester.tap(find.text(fr.listingReportAction));
      await tester.pumpAndSettle();

      expect(find.text(fr.reportSheetQuestion), findsOneWidget);
      await tester.tap(find.text(fr.reportReasonScam));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, fr.reportDetailsLabel),
        'Demande un acompte',
      );
      await tapText(tester, fr.reportSubmit);

      expect(listings.reports, [
        ('listing-1', ReportReason.scam, 'Demande un acompte'),
      ]);
      expect(find.text(fr.reportSent), findsOneWidget);
    });

    testWidgets('signaler depuis le menu ⋯', (tester) async {
      await pump(tester);

      await tester.tap(find.byTooltip(fr.listingMoreTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(fr.listingReportAction).last);
      await tester.pumpAndSettle();

      expect(find.text(fr.reportSheetQuestion), findsOneWidget);
      // Sans motif, l'envoi est impossible.
      final submit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, fr.reportSubmit),
      );
      expect(submit.onPressed, isNull);
    });
  });

  group('Annonces similaires', () {
    testWidgets('grille, puis ouverture d’une autre annonce', (tester) async {
      listings.similar = Ok(<ListingSummary>[sampleListing(2)]);
      final router = await pump(tester);

      await scrollTo(tester, find.byType(ListingCard));
      expect(find.text(fr.listingSimilarTitle), findsOneWidget);

      await tester.tap(find.byType(ListingCard));
      await tester.pumpAndSettle();

      // Nouvelle page par-dessus la première (retour possible).
      expect(listings.detailCalls, ['listing-1', 'l2']);
      expect(router.canPop(), isTrue);
    });

    testWidgets('aucune : section masquée', (tester) async {
      await pump(tester);

      await scrollTo(tester, find.text(fr.listingReportAction));

      expect(find.text(fr.listingSimilarTitle), findsNothing);
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

    testWidgets('texte doublé, arabe, sombre : aucun débordement', (
      tester,
    ) async {
      listings.similar = Ok(<ListingSummary>[sampleListing(2)]);
      await pump(
        tester,
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
        textScale: 2,
      );
      await tester.drag(scrollable(), const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
