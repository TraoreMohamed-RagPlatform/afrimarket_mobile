import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

Widget _bar({
  double width = 360,
  int currentIndex = 0,
  int messages = 0,
  ValueChanged<int>? onSelect,
  VoidCallback? onPublish,
}) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: SizedBox(
      width: width,
      child: AppBottomNavBar(
        currentIndex: currentIndex,
        onSelect: onSelect ?? (_) {},
        items: [
          AppNavItem(
            icon: AppIcons.house,
            selectedIcon: AppIconsFill.house,
            label: fr.navHome,
          ),
          AppNavItem(
            icon: AppIcons.star,
            selectedIcon: AppIconsFill.star,
            label: fr.navFavorites,
          ),
          AppNavItem(
            icon: AppIcons.chatCircle,
            selectedIcon: AppIconsFill.chatCircle,
            label: fr.navMessages,
            badgeCount: messages,
          ),
          AppNavItem(
            icon: AppIcons.bell,
            selectedIcon: AppIconsFill.bell,
            label: fr.navNotifications,
          ),
        ],
        centerAction: AppNavAction(
          icon: AppIcons.plusCircle,
          label: fr.navPublish,
          onTap: onPublish ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('affiche les 4 onglets et l’action centrale', (tester) async {
    await tester.pumpWidget(localizedApp(_bar()));

    for (final label in [
      fr.navHome,
      fr.navFavorites,
      fr.navPublish,
      fr.navMessages,
      fr.navNotifications,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('« Publier » est au milieu', (tester) async {
    await tester.pumpWidget(localizedApp(_bar()));

    final publish = tester.getCenter(find.text(fr.navPublish)).dx;
    final favorites = tester.getCenter(find.text(fr.navFavorites)).dx;
    final messages = tester.getCenter(find.text(fr.navMessages)).dx;
    expect(publish, greaterThan(favorites));
    expect(publish, lessThan(messages));
  });

  testWidgets('toucher un onglet le sélectionne', (tester) async {
    int? selected;
    await tester.pumpWidget(
      localizedApp(_bar(onSelect: (index) => selected = index)),
    );

    await tester.tap(find.text(fr.navMessages));

    expect(selected, 2);
  });

  testWidgets('toucher « Publier » n’est pas un changement d’onglet', (
    tester,
  ) async {
    int? selected;
    var published = false;
    await tester.pumpWidget(
      localizedApp(
        _bar(
          onSelect: (index) => selected = index,
          onPublish: () => published = true,
        ),
      ),
    );

    await tester.tap(find.text(fr.navPublish));

    expect(published, isTrue);
    expect(selected, isNull);
  });

  testWidgets('onglet actif : icône pleine et annoncé « sélectionné »', (
    tester,
  ) async {
    await tester.pumpWidget(localizedApp(_bar(currentIndex: 1)));

    expect(find.byIcon(AppIconsFill.star), findsOneWidget);
    expect(find.byIcon(AppIcons.house), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(fr.navFavorites)),
      isSemantics(isSelected: true),
    );
  });

  testWidgets('pastille de non-lus, lue par les lecteurs d’écran', (
    tester,
  ) async {
    await tester.pumpWidget(localizedApp(_bar(messages: 3)));

    expect(find.text('3'), findsOneWidget);
    expect(
      find.bySemanticsLabel('${fr.navMessages}, ${fr.unreadCount(3)}'),
      findsOneWidget,
    );
  });

  testWidgets('au-delà de 99 : « 99+ »', (tester) async {
    await tester.pumpWidget(localizedApp(_bar(messages: 250)));

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('zones tactiles d’au moins 48 px de haut', (tester) async {
    await tester.pumpWidget(localizedApp(_bar()));

    final size = tester.getSize(find.bySemanticsLabel(fr.navHome));
    expect(size.height, greaterThanOrEqualTo(AppBottomNavBar.minTouchHeight));
  });

  testWidgets('« Publier » : icône au trait de la couleur de la marque', (
    tester,
  ) async {
    await tester.pumpWidget(localizedApp(_bar()));

    final context = tester.element(find.text(fr.navPublish));
    final icon = tester.widget<Icon>(find.byIcon(AppIcons.plusCircle));
    expect(icon.color, context.colors.brand);
    // Pas de rond plein : le bouton ne domine plus la barre.
    expect(
      find.descendant(
        of: find.bySemanticsLabel(fr.navPublish),
        matching: find.byType(Container),
      ),
      findsNothing,
    );
  });

  /// Libellés de la barre (les icônes sont aussi du texte, en Phosphor).
  Iterable<RenderParagraph> labels(WidgetTester tester) => find
      .byType(RichText)
      .evaluate()
      .map((element) => element.renderObject! as RenderParagraph)
      .where((p) => !(p.text.style?.fontFamily ?? '').startsWith('Phosphor'));

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('libellés lisibles : jamais sous 11 px (texte ×$scale)', (
      tester,
    ) async {
      for (final locale in const [Locale('fr'), Locale('en'), Locale('ar')]) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: localizedApp(_bar(), locale: locale),
          ),
        );

        for (final paragraph in labels(tester)) {
          final size = paragraph.textScaler.scale(
            paragraph.text.style!.fontSize!,
          );
          expect(
            size,
            greaterThanOrEqualTo(AppBottomNavBar.minLabelSize - 0.01),
          );
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('libellé trop long : réduit pour tenir, pas coupé', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: localizedApp(_bar(width: 600)),
      ),
    );

    final messages = labels(tester)
        .firstWhere((p) => p.text.toPlainText() == fr.navMessages);
    expect(
      messages.textScaler.scale(messages.text.style!.fontSize!),
      lessThan(12 * AppBottomNavBar.maxTextScale),
    );
    expect(
      messages.getMaxIntrinsicWidth(double.infinity),
      lessThanOrEqualTo(messages.size.width + 0.5),
    );
  });

  testWidgets('arabe, mode sombre et texte doublé', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(
          _bar(messages: 250),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
