import 'package:afrimarket_mobile/features/health/data/models/health_status_model.dart';
import 'package:afrimarket_mobile/features/health/domain/entities/health_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthStatusModel', () {
    test('lit une réponse valide', () {
      final model = HealthStatusModel.fromJson({
        'status': 'ok',
        'timestamp': '2026-09-29T00:00:00Z',
        'database': 'connected',
        'websocket': 'active',
      });

      expect(
        model.toEntity(),
        const HealthStatus(
          status: 'ok',
          database: 'connected',
          websocket: 'active',
        ),
      );
    });

    test('refuse un champ manquant', () {
      expect(
        () => HealthStatusModel.fromJson({'status': 'ok'}),
        throwsFormatException,
      );
    });

    test('refuse un type invalide', () {
      expect(
        () => HealthStatusModel.fromJson({
          'status': 42,
          'database': 'connected',
          'websocket': 'active',
        }),
        throwsFormatException,
      );
    });
  });

  group('HealthStatus', () {
    test('isHealthy dépend du statut', () {
      const ok = HealthStatus(status: 'ok', database: 'a', websocket: 'b');
      const ko = HealthStatus(status: 'error', database: 'a', websocket: 'b');

      expect(ok.isHealthy, isTrue);
      expect(ko.isHealthy, isFalse);
    });
  });
}
