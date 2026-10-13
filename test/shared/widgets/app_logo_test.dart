import 'package:afrimarket_mobile/core/theme/app_logo_colors.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

AppLogoPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(AppLogoMark),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as AppLogoPainter;
}

void main() {
  group('Couleurs selon le thème', () {
    testWidgets('clair : trait noir, nom de la couleur du pagne', (
      tester,
    ) async {
      await tester.pumpWidget(localizedApp(const AppLogo()));

      expect(_painter(tester).colors, AppLogoColors.light);
      final name = tester.widget<Text>(find.text(AppLogo.brandName));
      expect(name.style?.color, AppLogoColors.light.cloth);
    });

    testWidgets('sombre : trait blanc, pagne et nom plus clairs', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedApp(const AppLogo(), themeMode: ThemeMode.dark),
      );

      expect(_painter(tester).colors, AppLogoColors.dark);
      final name = tester.widget<Text>(find.text(AppLogo.brandName));
      expect(name.style?.color, AppLogoColors.dark.cloth);
    });

    test('le pagne et le nom partagent toujours la même couleur', () {
      expect(AppLogoColors.of(Brightness.light), AppLogoColors.light);
      expect(AppLogoColors.of(Brightness.dark), AppLogoColors.dark);
      expect(AppLogoColors.light.line, isNot(AppLogoColors.dark.line));
    });
  });

  group('Accessibilité', () {
    testWidgets('le logo est annoncé « AfriMarket », une seule fois', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(localizedApp(const Center(child: AppLogo())));

      expect(find.bySemanticsLabel(AppLogo.brandName), findsOneWidget);
      handle.dispose();
    });

    testWidgets('symbole seul : décoratif, sauf libellé fourni', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        localizedApp(
          const Column(
            children: [
              AppLogoMark(),
              AppLogoMark(semanticLabel: 'Accueil AfriMarket'),
            ],
          ),
        ),
      );

      expect(find.bySemanticsLabel('Accueil AfriMarket'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('toujours de gauche à droite, même en arabe', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          const Center(child: AppLogo()),
          locale: const Locale('ar'),
        ),
      );

      final mark = tester.getCenter(find.byType(AppLogoMark));
      final name = tester.getCenter(find.text(AppLogo.brandName));
      expect(mark.dx, lessThan(name.dx));
    });
  });

  group('Dessin', () {
    testWidgets('se dessine à toutes les étapes de l’animation', (
      tester,
    ) async {
      for (final t in [0.0, 0.2, 0.5, 0.8, 1.0]) {
        await tester.pumpWidget(
          localizedApp(
            Center(
              child: AppLogoLockup(
                height: 72,
                progress: AppLogoIntro.progressAt(t),
                nameReveal: AppLogoIntro.nameRevealAt(t),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 't = $t');
      }
    });

    test('ne redessine que si les couleurs ou l’avancement changent', () {
      const painter = AppLogoPainter(colors: AppLogoColors.light);

      expect(
        painter.shouldRepaint(
          const AppLogoPainter(colors: AppLogoColors.light),
        ),
        isFalse,
      );
      expect(
        painter.shouldRepaint(const AppLogoPainter(colors: AppLogoColors.dark)),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          const AppLogoPainter(
            colors: AppLogoColors.light,
            progress: AppLogoProgress(frame: 0.5),
          ),
        ),
        isTrue,
      );
    });

    test('avancement : égalité par valeur', () {
      expect(
        const AppLogoProgress(cloth: 0.3).hashCode,
        const AppLogoProgress(cloth: 0.3).hashCode,
      );
      expect(
        const AppLogoProgress(cloth: 0.3),
        isNot(AppLogoProgress.complete),
      );
    });
  });

  group('Chronologie de l’animation', () {
    test('au départ rien n’est dessiné, à la fin tout est en place', () {
      expect(
        AppLogoIntro.progressAt(0),
        const AppLogoProgress(
          frame: 0,
          basket: 0,
          wheels: 0,
          block: 0,
          cloth: 0,
          stripe: 0,
        ),
      );
      expect(AppLogoIntro.nameRevealAt(0), 0);
      expect(AppLogoIntro.progressAt(1), AppLogoProgress.complete);
      expect(AppLogoIntro.nameRevealAt(1), 1);
    });

    test('le chariot se dessine avant que le pagne tombe et le nom arrive', () {
      final early = AppLogoIntro.progressAt(0.3);

      expect(early.frame, greaterThan(0));
      expect(early.cloth, 0);
      expect(AppLogoIntro.nameRevealAt(0.3), 0);
    });

    test('dure 1,2 seconde', () {
      expect(AppLogoIntro.duration, const Duration(milliseconds: 1200));
    });
  });
}
