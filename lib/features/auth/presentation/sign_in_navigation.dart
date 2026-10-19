import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/navigation/safe_internal_path.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Onglets de la barre du bas : on y revient avec `go` (jamais empilés).
const Set<String> _tabs = {
  AppRoutes.home,
  AppRoutes.favorites,
  AppRoutes.messages,
  AppRoutes.notifications,
};

/// Quitte l'écran de connexion (ou d'inscription) une fois connecté, vers
/// la page demandée au départ ([returnTo], chemin interne sûr seulement).
///
/// Pourquoi ici et pas seulement dans le routeur : quand une page protégée
/// a été OUVERTE PAR-DESSUS une autre (`push`, par exemple « Publier »),
/// la redirection automatique du routeur ne concerne que la page du
/// dessous ; sans ce retour explicite, l'écran de connexion resterait
/// affiché alors que la personne est connectée.
///
/// - aucune page demandée, connexion ouverte par-dessus : simple retour ;
/// - page plein écran demandée (Publier, Mon profil...) et connexion ouverte
///   par-dessus : la connexion est REMPLACÉE par cette page (le bouton
///   Retour ramène là où l'on était) ;
/// - onglet demandé, ou connexion ouverte seule (lien, onglet) : `go`.
void leaveAuthAfterSignIn(BuildContext context, String? returnTo) {
  if (!context.mounted) return;
  final target = safeInternalPath(returnTo);
  final isTab = target != null && _tabs.contains(Uri.parse(target).path);

  if (context.canPop() && !isTab) {
    if (target == null) {
      context.pop();
    } else {
      context.pushReplacement(target);
    }
    return;
  }
  context.go(target ?? AppRoutes.home);
}
