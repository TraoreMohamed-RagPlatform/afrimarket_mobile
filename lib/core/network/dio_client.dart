import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:dio/dio.dart';

/// Délais réseau de l'application.
abstract final class NetworkTimeouts {
  static const connect = Duration(seconds: 10);
  static const receive = Duration(seconds: 15);
  static const send = Duration(seconds: 15);
}

/// Crée le client HTTP de l'application pour l'environnement courant.
///
/// Sécurité (OWASP MASVS - NETWORK) :
/// - l'URL provient de [AppConfig], qui impose déjà HTTPS en staging
///   et en production ;
/// - les redirections sont désactivées : une redirection pourrait
///   envoyer la requête (et son token) vers un autre serveur ou en
///   HTTP non chiffré.
///
/// Les intercepteurs (token, refresh, logs) sont ajoutés séparément.
Dio createDio(AppConfig config) {
  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl.toString(),
      connectTimeout: NetworkTimeouts.connect,
      receiveTimeout: NetworkTimeouts.receive,
      sendTimeout: NetworkTimeouts.send,
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
      followRedirects: false,
    ),
  );
}
