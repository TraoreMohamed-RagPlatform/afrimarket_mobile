import 'dart:async';

import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/core/theme/app_theme.dart';
import 'package:afrimarket_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

/// Page de destination factice : affiche son adresse complète.
class RouteProbe extends StatelessWidget {
  const new(this.location, {super.key});

  final String location;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text('route:$location'));
}

/// Texte affiché par [RouteProbe] pour [location].
Finder findRoute(String location) => find.text('route:$location');

/// Ouvre un écran d'authentification dans un vrai routeur, en français.
///
/// [pages] associe un chemin à son écran ; toute autre route connue
/// (fil, connexion, inscription...) affiche une [RouteProbe].
Future<ProviderContainer> pumpAuthPage(
  WidgetTester tester, {
  required String initialLocation,
  required Map<String, Widget Function(GoRouterState state)> pages,
  List<Override> overrides = const [],
  Flavor flavor = Flavor.prod,

  /// Pages ouvertes AVANT `initialLocation` (la première est la racine) :
  /// permet de tester un retour en arrière.
  List<String> stack = const [],
  Locale locale = const Locale('fr'),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  // Écran haut : tout le formulaire est visible sans défilement.
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = _MockTokenStorage();
  when(tokens.hasTokens).thenAnswer((_) async => const Ok<bool>(false));

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig.fromValues(
          expected: flavor,
          flavorName: flavor.name,
          appName: 'AfriMarket',
          apiBaseUrl: flavor == Flavor.dev
              ? 'http://10.0.2.2:3000'
              : 'https://api.example.com',
          enableNetworkLogs: false,
        ),
      ),
      tokenStorageProvider.overrideWithValue(tokens),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  GoRoute route(String path) => GoRoute(
    path: path,
    builder: (context, state) =>
        pages[path]?.call(state) ?? RouteProbe(state.uri.toString()),
  );

  final router = GoRouter(
    initialLocation: stack.isEmpty ? initialLocation : stack.first,
    routes: [
      for (final path in {
        AppRoutes.home,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.diagnostics,
        ...pages.keys,
      })
        route(path),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();

  if (stack.isNotEmpty) {
    for (final location in [...stack.skip(1), initialLocation]) {
      unawaited(router.push<void>(location));
    }
    await tester.pumpAndSettle();
  }
  return container;
}

/// Zone de saisie du champ [AppTextField] dont le libellé est [label].
Finder fieldByLabel(String label) => find.descendant(
  of: find.widgetWithText(AppTextField, label),
  matching: find.byType(EditableText),
);
