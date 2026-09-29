import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/health/domain/entities/health_status.dart';
import 'package:afrimarket_mobile/features/health/domain/repositories/health_repository.dart';
import 'package:afrimarket_mobile/features/health/domain/usecases/check_health_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockHealthRepository extends Mock implements HealthRepository;

void main() {
  test('CheckHealthUseCase délègue au repository', () async {
    final repository = _MockHealthRepository();
    const status = HealthStatus(
      status: 'ok',
      database: 'connected',
      websocket: 'active',
    );
    when(repository.check)
        .thenAnswer((_) async => const Ok<HealthStatus>(status));

    final result = await CheckHealthUseCase(repository)();

    expect((result as Ok<HealthStatus>).value, status);
    verify(repository.check).called(1);
  });
}
