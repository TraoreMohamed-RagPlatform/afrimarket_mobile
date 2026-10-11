import 'package:afrimarket_mobile/core/error/failure.dart';

/// État d'un formulaire d'authentification (connexion, inscription).
sealed class AuthFormState {
  const new();
}

/// Formulaire en attente de saisie.
final class AuthFormIdle extends AuthFormState {
  const new();
}

/// Envoi en cours : le formulaire est désactivé.
final class AuthFormSubmitting extends AuthFormState {
  const new();
}

/// Le serveur a accepté : la session est ouverte.
final class AuthFormSucceeded extends AuthFormState {
  const new();
}

/// L'envoi a échoué.
final class AuthFormFailed extends AuthFormState {
  const new(this.failure);

  final Failure failure;
}
