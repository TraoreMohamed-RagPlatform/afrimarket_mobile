import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:dio/dio.dart';

/// Convertit une erreur Dio en [Failure] métier.
///
/// Sécurité (OWASP MASVS - PRIVACY / CODE) : le texte des erreurs
/// renvoyées par le serveur n'est JAMAIS repris (il peut contenir des
/// détails internes), à l'exception des messages de validation par champ.
Failure mapDioException(DioException exception) {
  return switch (exception.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const TimeoutFailure(),
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => const NetworkFailure(),
    DioExceptionType.badResponse => _mapResponse(exception.response),
    DioExceptionType.cancel ||
    DioExceptionType.unknown => const UnexpectedFailure(),
  };
}

Failure _mapResponse(Response<dynamic>? response) {
  final status = response?.statusCode;
  if (response == null || status == null) {
    return const UnexpectedFailure();
  }

  final data = response.data;
  final retryAfter = _parseRetryAfter(response);

  return switch (status) {
    400 ||
    409 ||
    422 => ValidationFailure(fieldErrors: _parseFieldErrors(data)),
    401 => const UnauthorizedFailure(),
    403 => const ForbiddenFailure(),
    404 => const NotFoundFailure(),
    423 => AccountLockedFailure(retryAfter: retryAfter),
    429 when _isAccountLocked(data) => AccountLockedFailure(
      retryAfter: retryAfter,
    ),
    429 => RateLimitFailure(retryAfter: retryAfter),
    >= 500 => ServerFailure(statusCode: status),
    _ => const UnexpectedFailure(),
  };
}

/// Lit l'en-tête standard `Retry-After` (en secondes), s'il existe.
Duration? _parseRetryAfter(Response<dynamic> response) {
  final raw = response.headers['retry-after']?.first;
  final seconds = int.tryParse(raw ?? '');
  if (seconds == null || seconds < 0) return null;
  return Duration(seconds: seconds);
}

/// Code d'erreur applicatif prévu pour le verrouillage de compte.
bool _isAccountLocked(Object? data) {
  return data is Map && data['code'] == 'ACCOUNT_LOCKED';
}

/// Lit les erreurs par champ au format express-validator :
/// `{ "errors": [ { "path": "email", "msg": "Invalid value" } ] }`
/// (`param` pour les anciennes versions d'express-validator).
///
/// Ne lève jamais d'exception, même si le JSON est inattendu.
Map<String, List<String>> _parseFieldErrors(Object? data) {
  if (data is! Map) return const {};

  final errors = data['errors'];
  if (errors is! List) return const {};

  final result = <String, List<String>>{};
  for (final item in errors) {
    if (item is! Map) continue;

    final field = item['path'] ?? item['param'];
    final message = item['msg'];
    if (field is String && message is String) {
      result.putIfAbsent(field, () => <String>[]).add(message);
    }
  }
  return result;
}
