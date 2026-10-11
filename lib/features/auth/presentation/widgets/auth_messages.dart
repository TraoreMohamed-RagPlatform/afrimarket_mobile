import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/features/auth/domain/validation/auth_validators.dart';

/// Message traduit pour un problème de saisie (ou `null` si aucun).
extension AuthFieldIssueMessage on AuthFieldIssue {
  String message(AppLocalizations l10n) {
    return switch (this) {
      AuthFieldIssue.empty => l10n.authFieldRequired,
      AuthFieldIssue.invalidEmail => l10n.authEmailInvalid,
      AuthFieldIssue.passwordTooShort => l10n.authPasswordTooShort,
      AuthFieldIssue.passwordTooLong => l10n.authPasswordTooLong,
      AuthFieldIssue.passwordMismatch => l10n.authPasswordMismatch,
      AuthFieldIssue.usernameTooShort => l10n.authUsernameTooShort,
      AuthFieldIssue.usernameTooLong => l10n.authUsernameTooLong,
      AuthFieldIssue.usernameInvalid => l10n.authUsernameInvalid,
      AuthFieldIssue.nameTooLong => l10n.authNameTooLong,
      AuthFieldIssue.codeInvalid => l10n.authCodeInvalid,
    };
  }
}

/// Transforme une règle du domaine en validateur de champ Flutter.
String? Function(String?) authFieldValidator(
  AuthFieldIssue? Function(String?) rule,
  AppLocalizations l10n,
) {
  return (value) => rule(value)?.message(l10n);
}

/// Messages d'erreur propres à l'authentification.
///
/// Sécurité (anti-énumération) : « e-mail inconnu » et « mauvais mot de
/// passe » donnent exactement le même message.
abstract final class AuthFailureMessages {
  /// Échec de la connexion.
  static String login(Failure failure, AppLocalizations l10n) {
    return switch (failure) {
      UnauthorizedFailure() => l10n.loginInvalidCredentials,
      ForbiddenFailure() => l10n.authForbidden,
      _ => failure.message(l10n),
    };
  }

  /// Échec de l'inscription.
  static String register(Failure failure, AppLocalizations l10n) {
    return switch (failure) {
      ValidationFailure() => l10n.registerRejected,
      ForbiddenFailure() => l10n.authForbidden,
      _ => failure.message(l10n),
    };
  }

  /// Échec de la réinitialisation (code refusé, expiré ou compte inconnu).
  static String reset(Failure failure, AppLocalizations l10n) {
    return switch (failure) {
      ValidationFailure() || NotFoundFailure() => l10n.resetCodeRejected,
      _ => failure.message(l10n),
    };
  }
}
