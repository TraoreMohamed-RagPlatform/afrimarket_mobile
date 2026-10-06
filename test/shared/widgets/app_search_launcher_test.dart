import 'package:afrimarket_mobile/shared/widgets/app_search_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

Widget _launcher({VoidCallback? onTap}) => Center(
  child: SizedBox(
    width: 300,
    child: AppSearchLauncher(hint: fr.searchHint, onTap: onTap ?? () {}),
  ),
);

void main() {
  testWidgets('affiche le texte et réagit au toucher', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      localizedApp(_launcher(onTap: () => tapped = true)),
    );

    expect(find.text(fr.searchHint), findsOneWidget);
    await tester.tap(find.byType(AppSearchLauncher));
    expect(tapped, isTrue);
  });

  testWidgets('zone tactile d’au moins 48 px', (tester) async {
    await tester.pumpWidget(localizedApp(_launcher()));

    final size = tester.getSize(find.byType(AppSearchLauncher));
    expect(size.height, greaterThanOrEqualTo(AppSearchLauncher.minTouchHeight));
  });

  testWidgets('annoncé comme un bouton aux lecteurs d’écran', (tester) async {
    await tester.pumpWidget(localizedApp(_launcher()));

    expect(find.bySemanticsLabel(fr.searchHint), findsOneWidget);
  });

  testWidgets('arabe, mode sombre et texte doublé', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(
          _launcher(),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
