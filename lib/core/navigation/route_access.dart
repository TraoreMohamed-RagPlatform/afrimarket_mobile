/// Niveau d'accès d'une page.
enum RouteAccess {
  /// Accessible à tous, connectés ou non.
  public,

  /// Accessible à tous, mais un visiteur y voit une invitation à se
  /// connecter au lieu du contenu (onglets Favoris, Messages...).
  signInPrompt,

  /// Réservée aux utilisateurs connectés : un visiteur est redirigé vers
  /// la connexion, puis ramené à la page demandée.
  authenticated,
}

/// Table d'accès CENTRALISÉE des pages (ADR 0002).
///
/// Sécurité (OWASP MASVS - AUTH) : « fermé par défaut ». Toute page qui
/// ne correspond à aucune règle est [RouteAccess.authenticated] : on ne
/// peut pas oublier de protéger une nouvelle page.
///
/// Les règles sont des expressions régulières STRICTES : un identifiant
/// d'annonce mal formé (ex. `/listings/<script>`) ne correspond à aucune
/// règle publique, et reste donc protégé.
abstract final class RouteAccessPolicy {
  /// Identifiant autorisé dans une adresse : 1 à 64 caractères sûrs.
  static const _id = '[A-Za-z0-9_-]{1,64}';

  static final List<(RegExp, RouteAccess)> _rules = [
    (RegExp(r'^/$'), RouteAccess.public),
    (RegExp(r'^/login$'), RouteAccess.public),
    (RegExp(r'^/search$'), RouteAccess.public),
    (RegExp('^/listings/$_id\$'), RouteAccess.public),
    (RegExp('^/sellers/$_id\$'), RouteAccess.public),
    (RegExp(r'^/dev/diagnostics$'), RouteAccess.public),
    (RegExp(r'^/favorites$'), RouteAccess.signInPrompt),
    (RegExp(r'^/messages$'), RouteAccess.signInPrompt),
    (RegExp(r'^/notifications$'), RouteAccess.signInPrompt),
    // Toute autre page (dont /publish) : authenticated, par défaut.
  ];

  /// Niveau d'accès de [path] (chemin seul, sans paramètres).
  static RouteAccess of(String path) {
    for (final (pattern, access) in _rules) {
      if (pattern.hasMatch(path)) return access;
    }
    return RouteAccess.authenticated;
  }
}
