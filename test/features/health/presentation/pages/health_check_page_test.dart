import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/health/domain/entities/health_status.dart';
import 'package:afrimarket_mobile/features/health/domain/usecases/check_health_usecase.dart';
import 'package:afrimarket_mobile/features/health/health_providers.dart';
import 'package:afrimarket_mobile/features/health/presentation/pages/health_check_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/l10n.dart';

class _MockCheckHealth extends Mock implements CheckHealthUseCase;

void main() {
  late _MockCheckHealth useCase;

  setUp(() => useCase = _MockCheckHealth());

  Future<void> pump(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(
              expected: Flavor.dev,
              flavorName: 'dev',
              appName: 'AfriMarket Dev',
              apiBaseUrl: 'http://10.0.2.2:3000',
              enableNetworkLogs: false,
            ),
          ),
          checkHealthUseCaseProvider.overrideWithValue(useCase),
        ],
        child: localizedApp(const HealthCheckPage()),
      ),
    );
  }

  testWidgets('affiche la consigne au départ', (tester) async {
    await pump(tester);

    expect(find.text(fr.diagnosticsIntro), findsOneWidget);
  });

  testWidgets('affiche le résultat du serveur', (tester) async {
    when(() => useCase()).thenAnswer(
      (_) async => const Ok<HealthStatus>(
        HealthStatus(status: 'ok', database: 'connected', websocket: 'active'),
      ),
    );
    await pump(tester);

    await tester.tap(find.text(fr.diagnosticsTestButton));
    await tester.pumpAndSettle();

    expect(
      find.text(fr.diagnosticsResult('ok', 'connected', 'active')),
      findsOneWidget,
    );
  });

  testWidgets('affiche le message traduit de la Failure', (tester) async {
    when(() => useCase())
        .thenAnswer((_) async => const Err<HealthStatus>(TimeoutFailure()));
    await pump(tester);

    await tester.tap(find.text(fr.diagnosticsTestButton));
    await tester.pumpAndSettle();

    expect(find.text(fr.errorTimeout), findsOneWidget);
  });
}
