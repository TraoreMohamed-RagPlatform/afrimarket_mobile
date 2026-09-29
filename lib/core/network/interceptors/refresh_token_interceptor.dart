import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

typedef _Tokens = ({String accessToken, String refreshToken});

/// Renouvelle automatiquement l'access token quand le serveur répond 401,
/// puis rejoue la requête d'origine.
///
/// Sécurité (OWASP MASVS - AUTH / NETWORK) :
/// - un seul refresh à la fois (les requêtes concurrentes attendent) ;
/// - une requête n'est rejouée qu'UNE fois (pas de boucle infinie) ;
/// - les routes publiques ne déclenchent jamais de refresh ;
/// - le refresh utilise un client Dio séparé, SANS intercepteurs ;
/// - la session n'est effacée que si le serveur REFUSE le refresh
///   (401 / 403) : une coupure réseau ne déconnecte pas l'utilisateur ;
/// - prêt pour la rotation : un nouveau refresh token renvoyé par le
///   serveur est enregistré, sinon l'ancien est conservé.
class RefreshTokenInterceptor extends Interceptor {
  new({
    required this._dio,
    required this._refreshDio,
    required this._tokenStorage,
    required this._apiBaseUrl,
    this._onSessionExpired,
  });

  /// Marque une requête déjà rejouée après un refresh.
  static const retriedKey = 'authRetried';

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _tokenStorage;
  final Uri _apiBaseUrl;
  final void Function()? _onSessionExpired;

  Future<Result<String>>? _refreshInFlight;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || !_isEligible(options)) {
      return handler.next(err);
    }

    final tokenResult = await _freshAccessToken(options);
    if (tokenResult case Ok(value: final token)) {
      try {
        options
          ..headers['Authorization'] = 'Bearer $token'
          ..extra[retriedKey] = true;
        final response = await _dio.fetch<dynamic>(options);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        return handler.next(retryError);
      }
    }
    return handler.next(err);
  }

  bool _isEligible(RequestOptions options) {
    if (options.extra[retriedKey] == true) return false;
    if (options.extra[AuthInterceptor.skipAuthKey] == true) return false;

    final uri = options.uri;
    final isOurApi =
        uri.scheme == _apiBaseUrl.scheme &&
        uri.host == _apiBaseUrl.host &&
        uri.port == _apiBaseUrl.port;

    return isOurApi && !ApiEndpoints.publicAuthRoutes.contains(uri.path);
  }

  /// Renvoie un access token valide : celui déjà renouvelé par une autre
  /// requête s'il existe, sinon lance (ou rejoint) un refresh.
  Future<Result<String>> _freshAccessToken(RequestOptions options) async {
    final sentHeader = options.headers['Authorization'];
    final current = await _tokenStorage.readAccessToken();

    if (current case Ok(value: final token?)
        when token.isNotEmpty && sentHeader != 'Bearer $token') {
      return Ok(token);
    }

    final refresh = _refreshInFlight ??= _refresh().whenComplete(() {
      _refreshInFlight = null;
    });
    return await refresh;
  }

  Future<Result<String>> _refresh() async {
    final stored = await _tokenStorage.readRefreshToken();
    final refreshToken = switch (stored) {
      Ok(value: final token?) when token.isNotEmpty => token,
      _ => null,
    };

    if (refreshToken == null) {
      await _expireSession();
      return const Err(UnauthorizedFailure());
    }

    final result = await guardApiCall<_Tokens>(() async {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data ?? const <String, dynamic>{};

      final accessToken = data['accessToken'];
      if (accessToken is! String || accessToken.isEmpty) {
        throw const FormatException('accessToken manquant');
      }

      final rotated = data['refreshToken'];
      return (
        accessToken: accessToken,
        refreshToken: rotated is String && rotated.isNotEmpty
            ? rotated
            : refreshToken,
      );
    });

    switch (result) {
      case Ok(:final value):
        final saved = await _tokenStorage.saveTokens(
          accessToken: value.accessToken,
          refreshToken: value.refreshToken,
        );
        if (saved case Err(:final failure)) {
          await _expireSession();
          return Err(failure);
        }
        return Ok(value.accessToken);
      case Err(:final failure):
        if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
          await _expireSession();
        }
        return Err(failure);
    }
  }

  Future<void> _expireSession() async {
    await _tokenStorage.clear();
    _onSessionExpired?.call();
  }
}
