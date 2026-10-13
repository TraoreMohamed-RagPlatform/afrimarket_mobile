import 'package:afrimarket_mobile/app/pages/splash_page.dart';
import 'package:afrimarket_mobile/app/router/splash_intro.dart';
import 'package:afrimarket_mobile/core/theme/app_logo_colors.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool reduceMotion = false,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(const SplashPage(), themeMode: themeMode),
    ),
  );
  return container;
}

void main() {
  testWidgets('le logo s’anime, puis l’écran signale la fin', (tester) async {
    final container = await _pump(tester);

    expect(find.byType(AppLogoIntro), findsOneWidget);
    expect(container.read(splashIntroFinishedProvider), isFalse);

    await tester.pump(AppLogoIntro.duration ~/ 2);
    expect(container.read(splashIntroFinishedProvider), isFalse);

    await tester.pump(AppLogoIntro.duration);
    await tester.pump();
    expect(container.read(splashIntroFinishedProvider), isTrue);
    expect(find.text(AppLogo.brandName), findsOneWidget);
  });

  testWidgets('« Réduire les animations » : logo complet, fin immédiate', (
    tester,
  ) async {
    final container = await _pump(tester, reduceMotion: true);
    await tester.pump();

    expect(container.read(splashIntroFinishedProvider), isTrue);
    final lockup = tester.widget<AppLogoLockup>(find.byType(AppLogoLockup));
    expect(lockup.progress, AppLogoProgress.complete);
    expect(lockup.nameReveal, 1);
  });

  testWidgets('fond crème en clair, comme l’icône de l’app', (tester) async {
    await _pump(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppLogoColors.light.canvas);
    await tester.pumpAndSettle();
  });

  testWidgets('fond sombre en mode sombre', (tester) async {
    await _pump(tester, themeMode: ThemeMode.dark);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppLogoColors.dark.canvas);
    await tester.pumpAndSettle();
  });

  testWidgets('annoncé aux lecteurs d’écran (chargement)', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(find.bySemanticsLabel(RegExp(fr.splashLoading)), findsOneWidget);
    await tester.pumpAndSettle();
    handle.dispose();
  });
}
