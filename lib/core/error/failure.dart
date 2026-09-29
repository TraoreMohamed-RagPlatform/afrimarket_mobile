import 'package:flutter/foundation.dart';

/// Erreur métier renvoyée par les repositories.
///
/// Règles de sécurité (OWASP MASVS - PRIVACY / CODE) :
/// - une Failure ne contient JAMAIS de message technique brut
///   (trace d'erreur, URL interne, requête SQL...) ;
/// - le texte affiché à l'utilisateur est choisi par la couche
///   présentation, à partir du type de Failure, et traduit.
///
/// La classe est scellée : un `switch` sur une Failure doit traiter
/// tous les cas, sinon le code ne compile pas.
@immutable
sealed class Failure {
  const new();
}

/// Pas de connexion Internet.
final class NetworkFailure extends Failure {
  const new();
}

/// Le serveur n'a pas répondu à temps.
final class TimeoutFailure extends Failure {
  const new();
}

/// 401 : session expirée ou invalide.
final class UnauthorizedFailure extends Failure {
  const new();
}

/// 403 : action non autorisée pour cet utilisateur.
final class ForbiddenFailure extends Failure {
  const new();
}

/// 404 : ressource introuvable.
final class NotFoundFailure extends Failure {
  const new();
}

/// 400 / 422 : données invalides.
///
/// [fieldErrors] associe un champ du formulaire (ex. "email")
/// à la liste de ses erreurs.
final class ValidationFailure extends Failure {
  const new({this.fieldErrors = const {}});

  final Map<String, List<String>> fieldErrors;
}

/// 429 : trop de requêtes (limitation côté serveur).
final class RateLimitFailure extends Failure {
  const new({this.retryAfter});

  /// Délai avant de pouvoir réessayer, s'il est connu.
  final Duration? retryAfter;
}

/// Compte temporairement bloqué après trop de tentatives de connexion.
final class AccountLockedFailure extends Failure {
  const new({this.retryAfter});

  /// Délai avant déblocage, s'il est connu.
  final Duration? retryAfter;
}

/// 5xx : erreur interne du serveur.
final class ServerFailure extends Failure {
  const new({this.statusCode});

  final int? statusCode;
}

/// Erreur de lecture / écriture du stockage sécurisé local.
final class StorageFailure extends Failure {
  const new();
}

/// Toute autre erreur non prévue.
final class UnexpectedFailure extends Failure {
  const new();
}
