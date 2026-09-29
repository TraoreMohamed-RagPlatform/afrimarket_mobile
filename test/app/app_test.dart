import 'package:afrimarket_mobile/app/app.dart';
import 'package:afrimarket_mobile/app/router/app_router.dart';
import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/network/session_expiry.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

AppConfig _config(Flavor flavor) {
  return AppConfig.fromValues(
    expected: flavor,
    flavorName: flavor.name,
    appName: 'AfriMarket',
    apiBaseUrl: flavor == Flavor.dev
        ? 'http://10.0.2.2:3000'
        : 'https://api.example.com',
    enableNetworkLogs: false,
  );
}

void main() {
  late _MockTokenStorage tokens;

  setUp(() {
    tokens = _MockTokenStorage();
    when(() => tokens.clear()).thenAnswer((_) async => const Ok<void>(null));
  });

  Future<ProviderContainer> startApp(
    WidgetTester tester, {
    required bool hasSession,
    Flavor flavor = Flavor.dev,
  }) async {
    when(() => tokens.hasTokens())
        .thenAnswer((_) async => Ok<bool>(hasSession));

    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_config(flavor)),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AfriMarketApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('Navigation', () {
    testWidgets('sans session : page de connexion', (tester) async {
      await startApp(tester, hasSession: false);

      expect(
        find.text('Écran de connexion : disponible en F3'),
        findsOneWidget,
      );
    });

    testWidgets('avec session : page d’accueil', (tester) async {
      await startApp(tester, hasSession: true);

      expect(
        find.text('Accueil : le fil d’annonces arrive en F4'),
        findsOneWidget,
      );
    });

    testWidgets('session expirée : retour à la connexion', (tester) async {
      final container = await startApp(tester, hasSession: true);

      container.read(sessionExpiryProvider.notifier).notify();
      await tester.pumpAndSettle();

      expect(
        find.text('Écran de connexion : disponible en F3'),
        findsOneWidget,
      );
    });

    testWidgets('dev : la page de diagnostic existe', (tester) async {
      final container = await startApp(tester, hasSession: false);

      container.read(appRouterProvider).go(AppRoutes.diagnostics);
      await tester.pumpAndSettle();

      expect(find.text('Tester la connexion'), findsOneWidget);
    });

    testWidgets('prod : la page de diagnostic n’existe pas', (tester) async {
      final container = await startApp(
        tester,
        hasSession: false,
        flavor: Flavor.prod,
      );

      container.read(appRouterProvider).go(AppRoutes.diagnostics);
      await tester.pumpAndSettle();

      expect(find.text('Tester la connexion'), findsNothing);
      expect(find.text('Page introuvable'), findsOneWidget);
    });
  });
}
