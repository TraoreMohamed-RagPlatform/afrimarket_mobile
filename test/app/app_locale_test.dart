import 'package:afrimarket_mobile/app/app.dart';
import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/l10n/locale_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/l10n.dart';

class _MockTokenStorage extends Mock implements TokenStorage;

void main() {
  final ar = lookupAppLocalizations(const Locale('ar'));
  final en = lookupAppLocalizations(const Locale('en'));

  Future<ProviderContainer> startApp(WidgetTester tester) async {
    final tokens = _MockTokenStorage();
    when(tokens.hasTokens).thenAnswer((_) async => const Ok<bool>(false));

    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(
            expected: Flavor.prod,
            flavorName: 'prod',
            appName: 'AfriMarket',
            apiBaseUrl: 'https://api.example.com',
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

  testWidgets('téléphone en français : app en français', (tester) async {
    useFrenchDevice(tester);
    await startApp(tester);

    expect(find.text(fr.loginComingSoon), findsOneWidget);
  });

  testWidgets('passe en arabe instantanément (droite à gauche)', (
    tester,
  ) async {
    useFrenchDevice(tester);
    final container = await startApp(tester);

    container.read(localeProvider.notifier).setLocale(const Locale('ar'));
    await tester.pumpAndSettle();

    final text = find.text(ar.loginComingSoon);
    expect(text, findsOneWidget);
    expect(Directionality.of(tester.element(text)), TextDirection.rtl);
  });

  testWidgets('passe en anglais instantanément', (tester) async {
    useFrenchDevice(tester);
    final container = await startApp(tester);

    container.read(localeProvider.notifier).setLocale(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text(en.loginComingSoon), findsOneWidget);
  });
}
