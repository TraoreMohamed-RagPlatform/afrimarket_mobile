import 'package:afrimarket_mobile/app/app.dart';
import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'l10n.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

/// Démarre l'application complète (routeur, thèmes, traductions), en
/// français, avec ou sans session, et attend la fin du démarrage.
Future<ProviderContainer> pumpAfriMarketApp(
  WidgetTester tester, {
  required bool hasSession,
  Flavor flavor = Flavor.dev,
}) async {
  useFrenchDevice(tester);

  final tokens = _MockTokenStorage();
  when(tokens.hasTokens).thenAnswer((_) async => Ok<bool>(hasSession));
  when(tokens.clear).thenAnswer((_) async => const Ok<void>(null));

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
