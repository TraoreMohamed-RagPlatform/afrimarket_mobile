import 'package:afrimarket_mobile/shared/widgets/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

void main() {
  testWidgets('titre annoncé comme en-tête', (tester) async {
    await tester.pumpWidget(
      localizedApp(const AppSectionHeader(title: 'Description')),
    );

    final node = tester.getSemantics(find.text('Description'));
    expect(node.flagsCollection.isHeader, isTrue);
  });

  testWidgets('lien « Voir plus »', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      localizedApp(
        AppSectionHeader(
          title: 'Description',
          actionLabel: fr.seeMore,
          onAction: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text(fr.seeMore));
    expect(tapped, isTrue);
  });

  testWidgets('titre cliquable avec flèche', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      localizedApp(
        AppSectionHeader(title: 'Vendeur', onTap: () => tapped = true),
      ),
    );

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    await tester.tap(find.text('Vendeur'));
    expect(tapped, isTrue);
  });

  testWidgets('arabe, mode sombre et texte doublé', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(
          AppSectionHeader(
            title: 'الوصف',
            actionLabel: 'عرض المزيد',
            onAction: () {},
          ),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
