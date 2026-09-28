import 'package:afrimarket_mobile/app/app.dart';
import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('affiche la page de diagnostic en dev', (tester) async {
    final config = AppConfig.fromValues(
      expected: Flavor.dev,
      flavorName: 'dev',
      appName: 'AfriMarket Dev',
      apiBaseUrl: 'http://10.0.2.2:3000',
      enableNetworkLogs: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const AfriMarketApp(),
      ),
    );

    expect(find.text('Tester la connexion'), findsOneWidget);
    expect(find.textContaining('Environnement : dev'), findsOneWidget);
  });
}
