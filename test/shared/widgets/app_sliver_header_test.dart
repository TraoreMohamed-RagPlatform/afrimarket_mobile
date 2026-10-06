import 'package:afrimarket_mobile/shared/widgets/app_sliver_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

Widget _page() => CustomScrollView(
  slivers: [
    AppSliverHeader(
      title: 'AfriMarket',
      leading: IconButton(
        tooltip: 'Menu',
        icon: const Icon(Icons.menu),
        onPressed: () {},
      ),
      actions: [
        IconButton(
          tooltip: 'Profil',
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () {},
        ),
      ],
      search: const Text('recherche'),
      bottom: const Text('pastilles'),
    ),
    SliverList.builder(
      itemCount: 50,
      itemBuilder: (context, i) => SizedBox(height: 100, child: Text('$i')),
    ),
  ],
);

void main() {
  testWidgets('affiche titre, actions, recherche et pastilles', (tester) async {
    await tester.pumpWidget(localizedApp(_page()));

    expect(find.text('AfriMarket'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsOneWidget);
    expect(find.byTooltip('Profil'), findsOneWidget);
    expect(find.text('recherche'), findsOneWidget);
    expect(find.text('pastilles'), findsOneWidget);
  });

  testWidgets('le titre est annoncé comme un en-tête', (tester) async {
    await tester.pumpWidget(localizedApp(_page()));

    final semantics = tester.getSemantics(find.text('AfriMarket'));
    expect(semantics.flagsCollection.isHeader, isTrue);
  });

  testWidgets('se masque en descendant, réapparaît en remontant', (
    tester,
  ) async {
    await tester.pumpWidget(localizedApp(_page()));
    final scroll = find.byType(CustomScrollView);

    await tester.drag(scroll, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('AfriMarket').hitTestable(), findsNothing);

    await tester.drag(scroll, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('AfriMarket').hitTestable(), findsOneWidget);
  });

  testWidgets('arabe, mode sombre et texte doublé', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(
          _page(),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
