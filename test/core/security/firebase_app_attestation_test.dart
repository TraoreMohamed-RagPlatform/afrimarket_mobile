import 'package:afrimarket_mobile/core/config/firebase_config.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/security/app_attestation.dart';
import 'package:afrimarket_mobile/core/security/firebase_app_attestation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppCheck extends Mock implements FirebaseAppCheck;

FirebaseConfig _config({Flavor flavor = Flavor.dev, String debugToken = ''}) {
  return FirebaseConfig.fromValues(
    flavor: flavor,
    apiKey: 'api-key',
    appId: '1:123:android:abc',
    messagingSenderId: '123',
    projectId: 'afrimarket-test',
    appCheckDebugToken: debugToken,
  )!;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AndroidDebugProvider());
    registerFallbackValue(const AppleDebugProvider());
  });

  late _MockAppCheck appCheck;

  setUp(() {
    appCheck = _MockAppCheck();
    when(
      () => appCheck.activate(
        providerAndroid: any(named: 'providerAndroid'),
        providerApple: any(named: 'providerApple'),
      ),
    ).thenAnswer((_) async {});
  });

  group('FirebaseAppAttestation', () {
    test('renvoie le jeton à usage unique de Firebase', () async {
      when(() => appCheck.getLimitedUseToken()).thenAnswer((_) async => 'tok');

      final token = await FirebaseAppAttestation(appCheck).limitedUseToken();

      expect(token, 'tok');
    });

    test('jeton vide : null', () async {
      when(() => appCheck.getLimitedUseToken()).thenAnswer((_) async => '');

      expect(await FirebaseAppAttestation(appCheck).limitedUseToken(), isNull);
    });

    test('erreur Firebase : null, sans exception', () async {
      when(() => appCheck.getLimitedUseToken())
          .thenThrow(FirebaseException(plugin: 'app-check', message: 'refusé'));

      expect(await FirebaseAppAttestation(appCheck).limitedUseToken(), isNull);
    });
  });

  group('initAppAttestation', () {
    test('sans configuration : aucune attestation ni Firebase', () async {
      var initialized = false;

      final attestation = await initAppAttestation(
        flavor: Flavor.dev,
        config: null,
        initializeFirebase: (_) async => initialized = true,
        appCheck: () => appCheck,
      );

      expect(attestation, isA<NoAppAttestation>());
      expect(initialized, isFalse);
      verifyNever(
        () => appCheck.activate(
          providerAndroid: any(named: 'providerAndroid'),
          providerApple: any(named: 'providerApple'),
        ),
      );
    });

    test('initialise Firebase avec les valeurs de la configuration', () async {
      FirebaseOptions? options;

      await initAppAttestation(
        flavor: Flavor.dev,
        config: _config(),
        initializeFirebase: (o) async => options = o,
        appCheck: () => appCheck,
      );

      expect(options?.apiKey, 'api-key');
      expect(options?.appId, '1:123:android:abc');
      expect(options?.messagingSenderId, '123');
      expect(options?.projectId, 'afrimarket-test');
    });

    test('dev : fournisseur debug avec le jeton de la configuration', () async {
      final attestation = await initAppAttestation(
        flavor: Flavor.dev,
        config: _config(debugToken: 'debug-token'),
        initializeFirebase: (_) async {},
        appCheck: () => appCheck,
      );

      final captured = verify(
        () => appCheck.activate(
          providerAndroid: captureAny(named: 'providerAndroid'),
          providerApple: captureAny(named: 'providerApple'),
        ),
      ).captured;
      final android = captured[0] as AndroidDebugProvider;
      final apple = captured[1] as AppleDebugProvider;

      expect(android.debugToken, 'debug-token');
      expect(apple.debugToken, 'debug-token');
      expect(attestation, isA<FirebaseAppAttestation>());
    });

    test('production : Play Integrity et App Attest', () async {
      await initAppAttestation(
        flavor: Flavor.prod,
        config: _config(flavor: Flavor.prod),
        initializeFirebase: (_) async {},
        appCheck: () => appCheck,
      );

      final captured = verify(
        () => appCheck.activate(
          providerAndroid: captureAny(named: 'providerAndroid'),
          providerApple: captureAny(named: 'providerApple'),
        ),
      ).captured;

      expect(captured[0], isA<AndroidPlayIntegrityProvider>());
      expect(captured[1], isA<AppleAppAttestWithDeviceCheckFallbackProvider>());
    });
  });
}
