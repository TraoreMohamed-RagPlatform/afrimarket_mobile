import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/listings/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
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
    when(() => tokens.hasTokens())
        .thenAnswer((_) async => const Ok<bool>(true));
    when(() => tokens.clear()).thenAnswer((_) async => const Ok<void>(null));
  });

  Future<ProviderContainer> pump(WidgetTester tester, Flavor flavor) async {
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
        child: const MaterialApp(home: HomePage()),
      ),
    );
    return container;
  }

  testWidgets('le bouton Diagnostic est visible en dev', (tester) async {
    await pump(tester, Flavor.dev);

    expect(find.text('Diagnostic (dev)'), findsOneWidget);
  });

  testWidgets('le bouton Diagnostic est absent en prod', (tester) async {
    await pump(tester, Flavor.prod);

    expect(find.text('Diagnostic (dev)'), findsNothing);
  });

  testWidgets('Se déconnecter termine la session', (tester) async {
    final container = await pump(tester, Flavor.prod);

    await tester.tap(find.byTooltip('Se déconnecter'));
    await tester.pump();

    expect(container.read(sessionProvider), SessionStatus.unauthenticated);
    verify(() => tokens.clear()).called(1);
  });
}
