import 'dart:math';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';

/// Message utilisateur traduit pour chaque [Failure].
///
/// Utilisation : `Text(failure.message(context.l10n))`.
///
/// Le `switch` est exhaustif : un nouveau type de Failure ne compile pas
/// tant que son message n'est pas défini.
///
/// Sécurité (OWASP MASVS - PRIVACY) : aucun message ne contient de
/// détail technique (code HTTP, texte du serveur...).
extension FailureMessage on Failure {
  String message(AppLocalizations l10n) {
    return switch (this) {
      NetworkFailure() => l10n.errorNetwork,
      TimeoutFailure() => l10n.errorTimeout,
      UnauthorizedFailure() => l10n.errorUnauthorized,
      ForbiddenFailure() => l10n.errorForbidden,
      NotFoundFailure() => l10n.errorNotFound,
      ValidationFailure() => l10n.errorValidation,
      RateLimitFailure(:final retryAfter) =>
        retryAfter == null
            ? l10n.errorRateLimit
            : l10n.errorRateLimitMinutes(_toMinutes(retryAfter)),
      AccountLockedFailure(:final retryAfter) =>
        retryAfter == null
            ? l10n.errorAccountLocked
            : l10n.errorAccountLockedMinutes(_toMinutes(retryAfter)),
      ServerFailure() => l10n.errorServer,
      StorageFailure() => l10n.errorStorage,
      UnexpectedFailure() => l10n.errorUnexpected,
    };
  }
}

/// Arrondit à la minute supérieure, avec un minimum d'une minute.
int _toMinutes(Duration duration) {
  return max(1, (duration.inSeconds / 60).ceil());
}
