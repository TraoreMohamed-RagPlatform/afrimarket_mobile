import 'package:afrimarket_mobile/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

Widget _bar({
  int currentIndex = 0,
  int messages = 0,
  ValueChanged<int>? onSelect,
  VoidCallback? onPublish,
}) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: SizedBox(
      width: 360,
      child: AppBottomNavBar(
        currentIndex: currentIndex,
        onSelect: onSelect ?? (_) {},
        items: [
          AppNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: fr.navHome,
          ),
          AppNavItem(
            icon: Icons.star_border,
            selectedIcon: Icons.star,
            label: fr.navFavorites,
          ),
          AppNavItem(
            icon: Icons.chat_bubble_outline,
            selectedIcon: Icons.chat_bubble,
            label: fr.navMessages,
            badgeCount: messages,
          ),
          AppNavItem(
            icon: Icons.notifications_none,
            selectedIcon: Icons.notifications,
            label: fr.navNotifications,
          ),
        ],
        centerAction: AppNavAction(
          icon: Icons.add,
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

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
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
