import 'package:afrimarket_mobile/core/config/config_exception.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:flutter/foundation.dart';

/// Configuration de l'application pour un environnement donné.
///
/// Les valeurs sont injectées au build via :
/// `--dart-define-from-file=config/<environnement>.json`
@immutable
final class AppConfig {
  const new _({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this._enableNetworkLogs,
  });

  /// Lit la configuration injectée au build, puis la valide.
  ///
  /// [expected] est l'environnement du point d'entrée (main_dev,
  /// main_staging ou main_prod). Il doit correspondre au fichier de
  /// configuration utilisé, sinon l'application refuse de démarrer.
  factory fromEnvironment({required Flavor expected}) {
    return AppConfig.fromValues(
      expected: expected,
      flavorName: const String.fromEnvironment('FLAVOR'),
      appName: const String.fromEnvironment('APP_NAME'),
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      enableNetworkLogs: const bool.fromEnvironment('ENABLE_NETWORK_LOGS'),
    );
  }

  /// Construit et valide une configuration (utilisé aussi par les tests).
  factory fromValues({
    required Flavor expected,
    required String flavorName,
    required String appName,
    required String apiBaseUrl,
    required bool enableNetworkLogs,
  }) {
    final flavor = _parseFlavor(flavorName);

    if (flavor != expected) {
      throw ConfigException(
        'Point d\'entrée "${expected.name}" lancé avec la configuration '
        '"${flavor.name}". Vérifiez --dart-define-from-file.',
      );
    }

    if (appName.trim().isEmpty) {
      throw const ConfigException('APP_NAME est vide.');
    }

    return AppConfig._(
      flavor: flavor,
      appName: appName,
      apiBaseUrl: _parseApiUrl(apiBaseUrl, flavor),
      enableNetworkLogs: enableNetworkLogs,
    );
  }

  final Flavor flavor;
  final String appName;
  final Uri apiBaseUrl;
  final bool _enableNetworkLogs;

  /// Logs réseau détaillés : uniquement en dev, jamais dans un build release.
  bool get networkLogsEnabled =>
      _enableNetworkLogs && flavor == Flavor.dev && !kReleaseMode;

  static Flavor _parseFlavor(String name) {
    if (name.isEmpty) {
      throw const ConfigException(
        'FLAVOR manquant. Lancez avec '
        '--dart-define-from-file=config/<environnement>.json',
      );
    }
    return Flavor.values.firstWhere(
      (f) => f.name == name,
      orElse: () => throw ConfigException('FLAVOR inconnu : "$name".'),
    );
  }

  static Uri _parseApiUrl(String raw, Flavor flavor) {
    final uri = Uri.tryParse(raw);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ConfigException('API_BASE_URL invalide : "$raw".');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ConfigException(
        'API_BASE_URL doit utiliser http ou https (reçu : "${uri.scheme}").',
      );
    }
    if (flavor.requiresHttps && uri.scheme != 'https') {
      throw ConfigException(
        'HTTPS obligatoire en ${flavor.name} (reçu : "${uri.scheme}").',
      );
    }
    return uri;
  }
}
