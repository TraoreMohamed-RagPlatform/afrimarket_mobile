import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Ajoute automatiquement `Authorization: Bearer <token>` aux requêtes.
///
/// Sécurité (OWASP MASVS - NETWORK / AUTH) : le token n'est envoyé que si
/// - la requête vise NOTRE API (même protocole, serveur et port) ;
/// - la route n'est pas publique (connexion, inscription, refresh...) ;
/// - la requête ne demande pas `skipAuth` dans `options.extra`.
class AuthInterceptor extends Interceptor {
  new({required this._tokenStorage, required this._apiBaseUrl});

  /// Clé à placer dans `options.extra` pour ne pas envoyer de token.
  static const skipAuthKey = 'skipAuth';

  final TokenStorage _tokenStorage;
  final Uri _apiBaseUrl;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_shouldAttachToken(options)) {
      return handler.next(options);
    }

    final result = await _tokenStorage.readAccessToken();
    if (result case Ok(value: final token?) when token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  bool _shouldAttachToken(RequestOptions options) {
    if (options.extra[skipAuthKey] == true) return false;

    final uri = options.uri;
    final isOurApi =
        uri.scheme == _apiBaseUrl.scheme &&
        uri.host == _apiBaseUrl.host &&
        uri.port == _apiBaseUrl.port;
    if (!isOurApi) return false;

    return !ApiEndpoints.publicAuthRoutes.contains(uri.path);
  }
}
