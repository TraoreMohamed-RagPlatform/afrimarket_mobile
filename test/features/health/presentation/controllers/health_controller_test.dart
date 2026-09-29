import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/health/domain/entities/health_status.dart';
import 'package:afrimarket_mobile/features/health/domain/usecases/check_health_usecase.dart';
import 'package:afrimarket_mobile/features/health/health_providers.dart';
import 'package:afrimarket_mobile/features/health/presentation/controllers/health_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCheckHealth extends Mock implements CheckHealthUseCase;

const _status = HealthStatus(
  status: 'ok',
  database: 'connected',
  websocket: 'active',
);

void main() {
  late _MockCheckHealth useCase;
  late ProviderContainer container;

  setUp(() {
    useCase = _MockCheckHealth();
    container = ProviderContainer(
      overrides: [checkHealthUseCaseProvider.overrideWithValue(useCase)],
    );
    addTearDown(container.dispose);
    // Garde le contrôleur autoDispose en vie pendant le test.
    container.listen(healthControllerProvider, (previous, next) {});
  });

  group('HealthController', () {
    test('démarre à HealthIdle', () {
      expect(container.read(healthControllerProvider), isA<HealthIdle>());
    });

    test('succès : HealthLoaded', () async {
      when(() => useCase())
          .thenAnswer((_) async => const Ok<HealthStatus>(_status));

      await container.read(healthControllerProvider.notifier).check();

      final state = container.read(healthControllerProvider);
      expect((state as HealthLoaded).status, _status);
    });

    test('échec : HealthFailed avec la Failure', () async {
      when(() => useCase())
          .thenAnswer((_) async => const Err<HealthStatus>(TimeoutFailure()));

      await container.read(healthControllerProvider.notifier).check();

      final state = container.read(healthControllerProvider);
      expect((state as HealthFailed).failure, isA<TimeoutFailure>());
    });

    test('un seul test à la fois', () async {
      when(() => useCase())
          .thenAnswer((_) async => const Ok<HealthStatus>(_status));
      final controller = container.read(healthControllerProvider.notifier);

      await Future.wait([controller.check(), controller.check()]);

      verify(() => useCase()).called(1);
    });
  });
}
