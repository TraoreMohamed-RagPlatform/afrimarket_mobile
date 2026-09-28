import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/config_exception.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    AppConfig build({
      Flavor expected = Flavor.dev,
      String flavorName = 'dev',
      String appName = 'AfriMarket Dev',
      String apiBaseUrl = 'http://10.0.2.2:3000',
      bool enableNetworkLogs = true,
    }) {
      return AppConfig.fromValues(
        expected: expected,
        flavorName: flavorName,
        appName: appName,
        apiBaseUrl: apiBaseUrl,
        enableNetworkLogs: enableNetworkLogs,
      );
    }

    final throwsConfigException = throwsA(isA<ConfigException>());

    test('accepte une configuration dev en HTTP', () {
      final config = build();

      expect(config.flavor, Flavor.dev);
      expect(config.apiBaseUrl.host, '10.0.2.2');
      expect(config.apiBaseUrl.port, 3000);
    });

    test('accepte une configuration prod en HTTPS', () {
      final config = build(
        expected: Flavor.prod,
        flavorName: 'prod',
        apiBaseUrl: 'https://api.example.com',
      );

      expect(config.flavor, Flavor.prod);
      expect(config.apiBaseUrl.scheme, 'https');
    });

    test('refuse HTTP en production', () {
      expect(
        () => build(
          expected: Flavor.prod,
          flavorName: 'prod',
          apiBaseUrl: 'http://api.example.com',
        ),
        throwsConfigException,
      );
    });

    test('refuse HTTP en staging', () {
      expect(
        () => build(
          expected: Flavor.staging,
          flavorName: 'staging',
          apiBaseUrl: 'http://api-staging.example.com',
        ),
        throwsConfigException,
      );
    });

    test('refuse un FLAVOR absent', () {
      expect(() => build(flavorName: ''), throwsConfigException);
    });

    test('refuse un FLAVOR inconnu', () {
      expect(() => build(flavorName: 'qa'), throwsConfigException);
    });

    test('refuse une incohérence entre point d’entrée et config', () {
      expect(() => build(expected: Flavor.prod), throwsConfigException);
    });

    test('refuse une URL invalide', () {
      expect(() => build(apiBaseUrl: 'pas-une-url'), throwsConfigException);
    });

    test('refuse un APP_NAME vide', () {
      expect(() => build(appName: '  '), throwsConfigException);
    });

    test('désactive les logs réseau hors environnement dev', () {
      final config = build(
        expected: Flavor.prod,
        flavorName: 'prod',
        apiBaseUrl: 'https://api.example.com',
      );

      expect(config.networkLogsEnabled, isFalse);
    });
  });
}
