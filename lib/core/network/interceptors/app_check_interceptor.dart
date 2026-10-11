import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/security/app_attestation.dart';
import 'package:dio/dio.dart';

/// Ajoute la preuve App Check (`X-Firebase-AppCheck`) aux requêtes sensibles
/// (connexion, inscription, formulaire de contact).
///
/// Sécurité (OWASP MASVS - RESILIENCE / NETWORK) :
/// - jeton à usage unique, demandé pour chaque requête (le serveur refuse
///   un jeton rejoué) ;
/// - envoyé uniquement à NOTRE API (même protocole, serveur et port) et
///   seulement sur les routes qui l'exigent ;
/// - sans jeton disponible, la requête part sans en-tête et le serveur la
///   refuse (403) : jamais de contournement côté application.
class AppCheckInterceptor extends Interceptor {
  new({required this._attestation, required this._apiBaseUrl});

  /// En-tête attendu par le backend (middleware verifyClient).
  static const headerName = 'X-Firebase-AppCheck';

  final AppAttestation _attestation;
  final Uri _apiBaseUrl;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_requiresAttestation(options)) {
      final token = await _attestation.limitedUseToken();
      if (token != null && token.isNotEmpty) {
        options.headers[headerName] = token;
      }
    }
    handler.next(options);
  }

  bool _requiresAttestation(RequestOptions options) {
    final uri = options.uri;
    final isOurApi =
        uri.scheme == _apiBaseUrl.scheme &&
        uri.host == _apiBaseUrl.host &&
        uri.port == _apiBaseUrl.port;

    return isOurApi && ApiEndpoints.attestedRoutes.contains(uri.path);
  }
}
