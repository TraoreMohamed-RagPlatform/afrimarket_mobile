/// Liste centralisée des routes de l'application.
///
/// Aucun chemin de navigation ne doit être écrit en dur ailleurs.
/// Les règles d'accès sont dans `RouteAccessPolicy` (route_access.dart).
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';

  /// Le fil d'annonces (adresse racine, utilisée par les liens partagés).
  static const home = '/';
  static const search = '/search';

  // Onglets de la barre du bas.
  static const favorites = '/favorites';
  static const messages = '/messages';
  static const notifications = '/notifications';

  /// Publication d'une annonce (plein écran, hors onglets).
  static const publish = '/publish';

  /// Détail d'une annonce : modèle de route et constructeur d'adresse.
  static const listingPattern = '/listings/:id';
  static String listing(String id) => '/listings/${Uri.encodeComponent(id)}';

  /// Profil public d'un vendeur.
  static const sellerPattern = '/sellers/:id';
  static String seller(String id) => '/sellers/${Uri.encodeComponent(id)}';

  /// Page de diagnostic : déclarée UNIQUEMENT dans le flavor dev.
  static const diagnostics = '/dev/diagnostics';

  /// Routes vers lesquelles on ne redirige jamais après connexion
  /// (évite les boucles).
  static const noReturnRoutes = <String>{splash, login};
}
