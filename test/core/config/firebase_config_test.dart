import 'package:afrimarket_mobile/core/config/config_exception.dart';
import 'package:afrimarket_mobile/core/config/firebase_config.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseConfig', () {
    FirebaseConfig? build({
      Flavor flavor = Flavor.dev,
      String apiKey = 'api-key',
      String appId = '1:123:android:abc',
      String messagingSenderId = '123',
      String projectId = 'afrimarket-test',
      String appCheckDebugToken = '',
    }) {
      return FirebaseConfig.fromValues(
        flavor: flavor,
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        appCheckDebugToken: appCheckDebugToken,
      );
    }

    final throwsConfigException = throwsA(isA<ConfigException>());

    test('configuration complète : valeurs conservées', () {
      final config = build()!;

      expect(config.apiKey, 'api-key');
      expect(config.appId, '1:123:android:abc');
      expect(config.messagingSenderId, '123');
      expect(config.projectId, 'afrimarket-test');
      expect(config.appCheckDebugToken, isNull);
    });

    test('dev sans aucune valeur : Firebase désactivé (null)', () {
      expect(
        build(apiKey: '', appId: '', messagingSenderId: '', projectId: ''),
        isNull,
      );
    });

    test('staging et prod sans configuration : démarrage refusé', () {
      for (final flavor in [Flavor.staging, Flavor.prod]) {
        expect(
          () => build(
            flavor: flavor,
            apiKey: '',
            appId: '',
            messagingSenderId: '',
            projectId: '',
          ),
          throwsConfigException,
        );
      }
    });

    test('configuration incomplète : démarrage refusé', () {
      expect(() => build(appId: ''), throwsConfigException);
      expect(() => build(projectId: '  '), throwsConfigException);
    });

    test('jeton de débogage accepté en dev et en staging', () {
      expect(build(appCheckDebugToken: 'debug')!.appCheckDebugToken, 'debug');
      expect(
        build(
          flavor: Flavor.staging,
          appCheckDebugToken: 'debug',
        )!.appCheckDebugToken,
        'debug',
      );
    });

    test('jeton de débogage interdit en production', () {
      expect(
        () => build(flavor: Flavor.prod, appCheckDebugToken: 'debug'),
        throwsConfigException,
      );
    });

    test('production sans jeton de débogage : acceptée', () {
      expect(build(flavor: Flavor.prod), isNotNull);
    });
  });
}
