import 'package:afrimarket_mobile/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

// Animation continue : utiliser pump(), jamais pumpAndSettle().
Widget _skeleton() =>
    const SizedBox(width: 360, height: 600, child: ListingGridSkeleton());

void main() {
  testWidgets('affiche les squelettes de cartes', (tester) async {
    await tester.pumpWidget(localizedApp(Center(child: _skeleton())));

    // 6 cartes = 6 photos + 6 lignes de texte.
    expect(find.byType(AppSkeletonBox), findsNWidgets(12));
  });

  testWidgets('annoncé une seule fois aux lecteurs d’écran', (tester) async {
    await tester.pumpWidget(localizedApp(Center(child: _skeleton())));

    expect(find.bySemanticsLabel(fr.loadingLabel), findsOneWidget);
  });

  testWidgets('pulse si les animations sont actives', (tester) async {
    await tester.pumpWidget(localizedApp(Center(child: _skeleton())));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('immobile si « Réduire les animations »', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: localizedApp(Center(child: _skeleton())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('arabe, mode sombre et texte doublé', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(
          Center(child: _skeleton()),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
