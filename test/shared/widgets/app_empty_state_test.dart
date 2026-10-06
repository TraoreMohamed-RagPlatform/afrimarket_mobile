import 'package:afrimarket_mobile/shared/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

Widget _empty({VoidCallback? onAction}) => AppEmptyState(
  icon: Icons.inventory_2_outlined,
  title: 'Publiez votre première annonce',
  message: 'Vendez ce dont vous n’avez plus besoin.',
  actionLabel: 'Publier',
  onAction: onAction ?? () {},
);

void main() {
  testWidgets('titre, message et action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      localizedApp(_empty(onAction: () => tapped = true)),
    );

    expect(find.text('Publiez votre première annonce'), findsOneWidget);
    await tester.tap(find.text('Publier'));
    expect(tapped, isTrue);
  });

  testWidgets('le titre est annoncé comme un en-tête', (tester) async {
    await tester.pumpWidget(localizedApp(_empty()));

    final node = tester.getSemantics(
      find.text('Publiez votre première annonce'),
    );
    expect(node.flagsCollection.isHeader, isTrue);
  });

  testWidgets('arabe, mode sombre et texte doublé', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(
          _empty(),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
