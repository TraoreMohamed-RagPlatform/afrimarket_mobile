import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<void> _pump(WidgetTester tester, Flavor flavor) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(_config(flavor))],
      child: const MaterialApp(home: LoginPage()),
    ),
  );
}

void main() {
  testWidgets('le bouton Diagnostic est visible en dev', (tester) async {
    await _pump(tester, Flavor.dev);

    expect(find.text('Diagnostic (dev)'), findsOneWidget);
  });

  testWidgets('le bouton Diagnostic est absent en prod', (tester) async {
    await _pump(tester, Flavor.prod);

    expect(find.text('Diagnostic (dev)'), findsNothing);
  });
}
