import 'package:afrimarket_mobile/shared/widgets/app_badge.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

/// Carte de test, SANS Scaffold : vérifie que le widget est autonome.
Widget _card({
  List<AppBadgeType> badges = const [],
  ListingCardStatus status = ListingCardStatus.available,
  num? oldPrice,
  Widget? action,
  VoidCallback? onTap,
  double width = 180,
}) {
  return Center(
    child: SizedBox(
      width: width,
      child: ListingCard(
        title: 'Appartement',
        price: 1400,
        oldPrice: oldPrice,
        badges: badges,
        status: status,
        action: action,
        onTap: onTap ?? () {},
      ),
    ),
  );
}

String _plain(String text) => text.replaceAll(RegExp('[\u00A0\u202F]'), ' ');

void main() {
  group('Affichage', () {
    testWidgets('affiche « prix · titre » sans Scaffold', (tester) async {
      await tester.pumpWidget(localizedApp(_card()));

      final text = tester.widget<Text>(find.textContaining('Appartement'));
      expect(_plain(text.textSpan!.toPlainText()), '1 400 DH · Appartement');
      expect(tester.takeException(), isNull);
    });

    testWidgets('aucun badge par défaut', (tester) async {
      await tester.pumpWidget(localizedApp(_card()));

      expect(find.byType(AppBadge), findsNothing);
    });

    testWidgets('affiche plusieurs badges', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          _card(badges: const [AppBadgeType.recent, AppBadgeType.verified]),
        ),
      );

      expect(find.byType(AppBadge), findsNWidgets(2));
    });

    testWidgets('limite le nombre de badges affichés', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          _card(
            badges: const [
              AppBadgeType.recent,
              AppBadgeType.verified,
              AppBadgeType.recent,
            ],
          ),
        ),
      );

      expect(
        find.byType(AppBadge),
        findsNWidgets(ListingCard.maxVisibleBadges),
      );
    });
  });

  group('Statuts', () {
    testWidgets('réservé : badge « Réservé » affiché en premier', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedApp(
          _card(
            status: ListingCardStatus.reserved,
            badges: const [AppBadgeType.recent, AppBadgeType.verified],
          ),
        ),
      );

      final shown = tester.widgetList<AppBadge>(find.byType(AppBadge));
      expect(shown.map((b) => b.type), [
        AppBadgeType.reserved,
        AppBadgeType.recent,
      ]);
    });

    testWidgets('vendu : photo en noir et blanc et mention « Vendu »', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedApp(_card(status: ListingCardStatus.sold)),
      );

      expect(find.byType(ColorFiltered), findsOneWidget);
      expect(find.text(fr.listingStatusSold), findsOneWidget);
    });

    testWidgets('disponible : photo en couleur', (tester) async {
      await tester.pumpWidget(localizedApp(_card()));

      expect(find.byType(ColorFiltered), findsNothing);
    });
  });

  group('Interactions', () {
    testWidgets('toucher la carte appelle onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(localizedApp(_card(onTap: () => tapped = true)));

      await tester.tap(find.byType(ListingCard));

      expect(tapped, isTrue);
    });

    testWidgets('toucher l’action n’ouvre pas l’annonce', (tester) async {
      var cardTapped = false;
      var actionTapped = false;
      await tester.pumpWidget(
        localizedApp(
          _card(
            onTap: () => cardTapped = true,
            action: IconButton(
              tooltip: 'Enregistrer',
              icon: const Icon(Icons.favorite_border),
              onPressed: () => actionTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Enregistrer'));

      expect(actionTapped, isTrue);
      expect(cardTapped, isFalse);
    });
  });

  group('Accessibilité', () {
    testWidgets('libellé pour les lecteurs d’écran', (tester) async {
      await tester.pumpWidget(localizedApp(_card()));

      expect(
        find.bySemanticsLabel(RegExp(r'^1.400 DH, Appartement$')),
        findsOneWidget,
      );
    });

    testWidgets('le statut est annoncé aux lecteurs d’écran', (tester) async {
      await tester.pumpWidget(
        localizedApp(_card(status: ListingCardStatus.sold)),
      );

      expect(
        find.bySemanticsLabel(RegExp('^${fr.listingStatusSold}, ')),
        findsOneWidget,
      );
    });

    testWidgets('l’action reste accessible séparément', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          _card(
            action: Semantics(
              label: 'Enregistrer',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Enregistrer'), findsOneWidget);
    });

    testWidgets('arabe, mode sombre et texte doublé : aucun débordement', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: localizedApp(
            _card(
              width: 150,
              status: ListingCardStatus.reserved,
              badges: const [AppBadgeType.recent],
              oldPrice: 2000,
              action: IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
            ),
            locale: const Locale('ar'),
            themeMode: ThemeMode.dark,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
