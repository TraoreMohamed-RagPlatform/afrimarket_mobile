import 'package:afrimarket_mobile/shared/widgets/app_rating_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

void main() {
  testWidgets('sans avis : « Nouveau vendeur »', (tester) async {
    await tester.pumpWidget(
      localizedApp(const Center(child: AppRatingSummary(average: 0, count: 0))),
    );

    expect(find.text(fr.sellerNew), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('avec avis : note et nombre', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        const Center(child: AppRatingSummary(average: 4.8, count: 12)),
      ),
    );

    expect(find.text('4,8 · ${fr.ratingCount(12)}'), findsOneWidget);
  });

  testWidgets('lecteurs d’écran : note sur 5 et nombre d’avis', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        const Center(child: AppRatingSummary(average: 4.8, count: 1)),
      ),
    );

    expect(
      find.bySemanticsLabel('${fr.ratingAverage('4,8')}, ${fr.ratingCount(1)}'),
      findsOneWidget,
    );
  });

  testWidgets('arabe, mode sombre et texte doublé', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(
          const Center(
            child: SizedBox(
              width: 120,
              child: AppRatingSummary(average: 4.8, count: 12),
            ),
          ),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
