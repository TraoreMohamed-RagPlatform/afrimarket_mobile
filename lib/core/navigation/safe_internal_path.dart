import 'package:afrimarket_mobile/core/navigation/app_routes.dart';

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
