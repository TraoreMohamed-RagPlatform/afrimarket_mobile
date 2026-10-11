import 'package:afrimarket_mobile/core/config/config_exception.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:flutter/foundation.dart';

/// Configuration Firebase de l'environnement courant.
///
/// Les valeurs viennent d'un fichier LOCAL, jamais committé (il contient une
/// clé d'API Google et, en développement, un jeton de débogage App Check) :
/// `--dart-define-from-file=config/firebase.<environnement>.json`
///
/// Modèle : `config/firebase.example.json`.
@immutable
final class FirebaseConfig {
  const new _({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.appCheckDebugToken,
  });

  /// Lit la configuration injectée au build, puis la valide
  /// (voir [fromValues]).
  static FirebaseConfig? fromEnvironment({required Flavor flavor}) {
    return FirebaseConfig.fromValues(
      flavor: flavor,
      apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
      appId: const String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId: const String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      ),
      projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    );
  }

  /// Construit et valide une configuration (utilisé aussi par les tests).
  ///
  /// Renvoie `null` si Firebase n'est pas configuré, ce qui n'est permis
  /// qu'en développement : en staging et en production, l'application
  /// refuse de démarrer (sans App Check, la connexion serait impossible).
  static FirebaseConfig? fromValues({
    required Flavor flavor,
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    required String projectId,
    String appCheckDebugToken = '',
  }) {
    final values = [apiKey, appId, messagingSenderId, projectId];
    final provided = values.where((v) => v.trim().isNotEmpty).length;

    if (provided == 0) {
      if (flavor == Flavor.dev) return null;
      throw ConfigException(
        'Configuration Firebase absente en ${flavor.name}. Ajoutez '
        '--dart-define-from-file=config/firebase.${flavor.name}.json',
      );
    }
    if (provided != values.length) {
      throw const ConfigException(
        'Configuration Firebase incomplète : FIREBASE_API_KEY, '
        'FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID et '
        'FIREBASE_PROJECT_ID sont tous requis.',
      );
    }

    // Le jeton de débogage ouvre App Check sans attestation réelle :
    // il est interdit en production.
    final debugToken = appCheckDebugToken.trim();
    if (flavor == Flavor.prod && debugToken.isNotEmpty) {
      throw const ConfigException(
        'APP_CHECK_DEBUG_TOKEN est interdit en production.',
      );
    }

    return FirebaseConfig._(
      apiKey: apiKey.trim(),
      appId: appId.trim(),
      messagingSenderId: messagingSenderId.trim(),
      projectId: projectId.trim(),
      appCheckDebugToken: debugToken.isEmpty ? null : debugToken,
    );
  }

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;

  /// Jeton de débogage App Check (dev et staging uniquement), ou `null` :
  /// le SDK en génère alors un et l'affiche dans les logs au premier
  /// lancement, à ajouter dans la console Firebase.
  final String? appCheckDebugToken;
}
