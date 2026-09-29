import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:afrimarket_mobile/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:afrimarket_mobile/core/network/interceptors/safe_log_interceptor.dart';
import 'package:afrimarket_mobile/core/network/network_providers.dart';
import 'package:afrimarket_mobile/core/network/session_expiry.dart';
import 'package:afrimarket_mobile/core/storage/secure_storage.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements SecureStorage;

AppConfig _config({required Flavor flavor, required bool logs}) {
  return AppConfig.fromValues(
    expected: flavor,
    flavorName: flavor.name,
    appName: 'AfriMarket',
    apiBaseUrl: flavor == Flavor.dev
        ? 'http://10.0.2.2:3000'
        : 'https://api.example.com',
    enableNetworkLogs: logs,
  );
}

ProviderContainer _container(AppConfig config) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      secureStorageProvider.overrideWithValue(_MockSecureStorage()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('dioProvider', () {
    test('contient les intercepteurs d’authentification et de refresh', () {
      final container = _container(_config(flavor: Flavor.prod, logs: false));
      final interceptors = container.read(dioProvider).interceptors;

      expect(interceptors.whereType<AuthInterceptor>(), hasLength(1));
      expect(interceptors.whereType<RefreshTokenInterceptor>(), hasLength(1));
    });

    test('active les logs en dev', () {
      final container = _container(_config(flavor: Flavor.dev, logs: true));
      final interceptors = container.read(dioProvider).interceptors;

      expect(interceptors.whereType<SafeLogInterceptor>(), hasLength(1));
    });

    test('aucun log réseau en production', () {
      final container = _container(_config(flavor: Flavor.prod, logs: true));
      final interceptors = container.read(dioProvider).interceptors;

      expect(interceptors.whereType<SafeLogInterceptor>(), isEmpty);
    });

    test('utilise l’URL de la configuration', () {
      final container = _container(_config(flavor: Flavor.prod, logs: false));

      expect(
        container.read(dioProvider).options.baseUrl,
        'https://api.example.com',
      );
    });
  });

  group('refreshDioProvider', () {
    test('n’a aucun intercepteur d’authentification', () {
      final container = _container(_config(flavor: Flavor.prod, logs: false));
      final interceptors = container.read(refreshDioProvider).interceptors;

      expect(interceptors.whereType<AuthInterceptor>(), isEmpty);
      expect(interceptors.whereType<RefreshTokenInterceptor>(), isEmpty);
      expect(interceptors.whereType<SafeLogInterceptor>(), isEmpty);
    });
  });

  group('sessionExpiryProvider', () {
    test('notify incrémente le compteur', () {
      final container = _container(_config(flavor: Flavor.prod, logs: false));

      expect(container.read(sessionExpiryProvider), 0);
      container.read(sessionExpiryProvider.notifier).notify();
      expect(container.read(sessionExpiryProvider), 1);
    });
  });
}
