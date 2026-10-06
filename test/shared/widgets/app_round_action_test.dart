import 'package:afrimarket_mobile/shared/widgets/app_round_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

Widget _action({bool active = false, VoidCallback? onTap}) => Center(
  child: AppRoundAction(
    icon: Icons.bookmark_border,
    activeIcon: Icons.bookmark,
    label: 'Enregistrer',
    activeLabel: 'Enregistré',
    active: active,
    onTap: onTap ?? () {},
  ),
);

void main() {
  group('AppRoundAction', () {
    testWidgets('affiche le libellé et réagit au toucher', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        localizedApp(_action(onTap: () => tapped = true)),
      );

      expect(find.text('Enregistrer'), findsOneWidget);
      await tester.tap(find.byType(AppRoundAction));
      expect(tapped, isTrue);
    });

    testWidgets('état actif : icône et libellé propres', (tester) async {
      await tester.pumpWidget(localizedApp(_action(active: true)));

      expect(find.text('Enregistré'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('annoncé comme interrupteur aux lecteurs d’écran', (
      tester,
    ) async {
      await tester.pumpWidget(localizedApp(_action(active: true)));

      final node = tester.getSemantics(find.bySemanticsLabel('Enregistré'));
      expect(node, isSemantics(isToggled: true));
    });

    testWidgets('zone tactile d’au moins 48 × 48', (tester) async {
      await tester.pumpWidget(localizedApp(_action()));

      final size = tester.getSize(find.byType(AppRoundAction));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('isolé : largeur maximale, même avec un long libellé', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedApp(
          Center(
            child: AppRoundAction(
              icon: Icons.circle_outlined,
              label: 'Un libellé beaucoup trop long pour un bouton',
              onTap: () {},
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AppRoundAction));
      expect(size.width, lessThanOrEqualTo(AppRoundAction.maxWidth));
    });

    testWidgets('arabe, mode sombre et texte doublé', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: localizedApp(
            _action(active: true),
            locale: const Locale('ar'),
            themeMode: ThemeMode.dark,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('AppRoundActionRow', () {
    // Toute erreur de mise en page fait échouer le test, avec son détail.
    for (final width in [280.0, 360.0]) {
      testWidgets('4 actions, texte doublé, écran de ${width.toInt()} px', (
        tester,
      ) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: localizedApp(
              Center(
                child: SizedBox(
                  width: width,
                  child: AppRoundActionRow(
                    actions: [
                      for (final label in [
                        'Alertes',
                        'Message',
                        'Partager',
                        'Enregistrer',
                      ])
                        AppRoundAction(
                          icon: Icons.circle_outlined,
                          label: label,
                          onTap: () {},
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(AppRoundAction), findsNWidgets(4));
      });
    }

    testWidgets('chaque action reçoit une part égale', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          Center(
            child: SizedBox(
              width: 300,
              child: AppRoundActionRow(
                actions: [
                  for (final label in ['A', 'B', 'C'])
                    AppRoundAction(
                      icon: Icons.circle_outlined,
                      label: label,
                      onTap: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      final centers = [
        for (final label in ['A', 'B', 'C'])
          tester.getCenter(find.text(label)).dx,
      ];
      // Centres espacés de 100 px (300 / 3).
      expect(centers[1] - centers[0], closeTo(100, 0.5));
      expect(centers[2] - centers[1], closeTo(100, 0.5));
    });
  });
}
