import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = AppConfig.fromValues(
    expected: Flavor.prod,
    flavorName: 'prod',
    appName: 'AfriMarket',
    apiBaseUrl: 'https://api.example.com',
    enableNetworkLogs: false,
  );

  group('createDio', () {
    test('utilise l’URL de la configuration', () {
      final dio = createDio(config);

      expect(dio.options.baseUrl, 'https://api.example.com');
    });

    test('applique les délais réseau', () {
      final dio = createDio(config);

      expect(dio.options.connectTimeout, NetworkTimeouts.connect);
      expect(dio.options.receiveTimeout, NetworkTimeouts.receive);
      expect(dio.options.sendTimeout, NetworkTimeouts.send);
    });

    test('échange du JSON', () {
      final dio = createDio(config);

      expect(dio.options.contentType, Headers.jsonContentType);
      expect(dio.options.headers['Accept'], 'application/json');
    });

    test('désactive les redirections (sécurité)', () {
      final dio = createDio(config);

      expect(dio.options.followRedirects, isFalse);
    });
  });

  group('ApiEndpoints', () {
    test('toutes les routes publiques sont sous /api/auth/', () {
      for (final route in ApiEndpoints.publicAuthRoutes) {
        expect(route, startsWith('/api/auth/'));
      }
    });

    test('les routes protégées ne sont pas publiques', () {
      expect(ApiEndpoints.publicAuthRoutes, isNot(contains(ApiEndpoints.me)));
      expect(
        ApiEndpoints.publicAuthRoutes,
        isNot(contains(ApiEndpoints.logout)),
      );
      expect(
        ApiEndpoints.publicAuthRoutes,
        isNot(contains(ApiEndpoints.changePassword)),
      );
    });
  });
}
