import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/navigation/route_access.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';

/// Paramètre qui mémorise la page demandée avant une redirection.
const fromParam = 'from';

/// Décide où envoyer l'utilisateur selon sa session et la page demandée
/// (consultation sans compte, ADR 0002).
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
      // Vérification de la session : la page demandée (ex. lien partagé)
      // est mémorisée et sera ouverte ensuite.
      if (path == AppRoutes.splash) return null;
      return _withFrom(AppRoutes.splash, location);

    case SessionStatus.unauthenticated:
      if (path == AppRoutes.splash) {
        return _guestDestination(location.queryParameters[fromParam]);
      }
      if (RouteAccessPolicy.of(path) == RouteAccess.authenticated) {
        return _withFrom(AppRoutes.login, location);
      }
      return null;

    case SessionStatus.authenticated:
      if (!AppRoutes.noReturnRoutes.contains(path)) return null;
      return safeInternalPath(location.queryParameters[fromParam]) ??
          AppRoutes.home;
  }
}

/// Destination d'un visiteur à la fin du démarrage : la page mémorisée si
/// elle est sûre (via la connexion si elle l'exige), sinon le fil.
String _guestDestination(String? from) {
  final target = safeInternalPath(from);
  if (target == null) return AppRoutes.home;

  final targetPath = Uri.parse(target).path;
  if (RouteAccessPolicy.of(targetPath) == RouteAccess.authenticated) {
    return Uri(
      path: AppRoutes.login,
      queryParameters: {fromParam: target},
    ).toString();
  }
  return target;
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
