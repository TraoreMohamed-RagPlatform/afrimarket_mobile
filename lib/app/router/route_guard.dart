import 'package:afrimarket_mobile/app/router/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';

/// Paramètre qui mémorise la page demandée avant une redirection.
const fromParam = 'from';

/// Décide où envoyer l'utilisateur selon sa session et la page demandée.
///
/// Renvoie `null` si la page demandée est autorisée, sinon le chemin
/// vers lequel rediriger.
///
/// Fonction pure (sans Flutter ni go_router) : toutes les règles
/// de navigation sont testables unitairement.
String? resolveRedirect({
  required SessionStatus status,
  required Uri location,
}) {
  final path = location.path;

  switch (status) {
    case SessionStatus.unknown:
      if (path == AppRoutes.splash) return null;
      return _withFrom(AppRoutes.splash, location);

    case SessionStatus.unauthenticated:
      if (AppRoutes.publicRoutes.contains(path)) return null;
      return _withFrom(AppRoutes.login, location);

    case SessionStatus.authenticated:
      if (!AppRoutes.noReturnRoutes.contains(path)) return null;
      return safeInternalPath(location.queryParameters[fromParam]) ??
          AppRoutes.home;
  }
}

/// Ajoute `?from=<page demandée>` si la page mérite d'être retenue.
String _withFrom(String target, Uri location) {
  final from = location.toString();
  if (safeInternalPath(from) == null) return target;
  return Uri(path: target, queryParameters: {fromParam: from}).toString();
}

/// Renvoie [candidate] seulement s'il s'agit d'un chemin INTERNE sûr.
///
/// Sécurité (CWE-601 - Open Redirect) : refuse les URL avec schéma
/// (`https://...`), les hôtes déguisés (`//site.com`), les antislashs,
/// et les routes qui provoqueraient une boucle.
String? safeInternalPath(String? candidate) {
  if (candidate == null || candidate.isEmpty) return null;
  if (!candidate.startsWith('/')) return null;
  if (candidate.startsWith('//')) return null;
  if (candidate.contains(r'\')) return null;

  final uri = Uri.tryParse(candidate);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (AppRoutes.noReturnRoutes.contains(uri.path)) return null;

  return candidate;
}
