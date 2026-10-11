import 'package:afrimarket_mobile/core/config/firebase_config.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/security/app_attestation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Attestation par Firebase App Check.
final class FirebaseAppAttestation implements AppAttestation {
  const new(this._appCheck);

  final FirebaseAppCheck _appCheck;

  @override
  Future<String?> limitedUseToken() async {
    try {
      final token = await _appCheck.getLimitedUseToken();
      return token.isEmpty ? null : token;
    } on Object {
      // Pas de réseau, attestation refusée... : la requête part sans
      // jeton et le backend la refuse. Aucun détail n'est journalisé.
      return null;
    }
  }
}

/// Initialise Firebase et App Check, puis renvoie l'attestation à utiliser.
///
/// Fournisseur d'attestation selon l'environnement :
/// - production : Play Integrity (Android) / App Attest (iOS) ;
/// - dev et staging : fournisseur « debug » (émulateur, installation hors
///   Play Store). Le jeton de débogage doit être déclaré dans la console.
Future<AppAttestation> initAppAttestation({
  required Flavor flavor,
  required FirebaseConfig? config,
}) async {
  if (config == null) {
    debugPrint(
      '[App Check] Firebase non configuré : connexion et inscription '
      'seront refusées par le serveur (voir config/firebase.example.json).',
    );
    return const NoAppAttestation();
  }

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: config.apiKey,
      appId: config.appId,
      messagingSenderId: config.messagingSenderId,
      projectId: config.projectId,
    ),
  );

  final appCheck = FirebaseAppCheck.instance;
  final useDebugProvider = flavor != Flavor.prod;

  await appCheck.activate(
    providerAndroid: useDebugProvider
        ? AndroidDebugProvider(debugToken: config.appCheckDebugToken)
        : const AndroidPlayIntegrityProvider(),
    providerApple: useDebugProvider
        ? AppleDebugProvider(debugToken: config.appCheckDebugToken)
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  return FirebaseAppAttestation(appCheck);
}
