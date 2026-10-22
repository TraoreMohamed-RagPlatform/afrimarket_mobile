/// Liste centralisée des routes de l'application.
///
/// Aucun chemin de navigation ne doit être écrit en dur ailleurs.
/// Les règles d'accès sont dans `RouteAccessPolicy` (route_access.dart).
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  /// Paramètre qui mémorise la page à rouvrir après la connexion.
  static const returnParam = 'from';

  /// Connexion, puis retour à [from] (chemin interne).
  static String loginWithReturn(String from) =>
      Uri(path: login, queryParameters: {returnParam: from}).toString();

  /// [path] avec `?from=<from>` si [from] est fourni.
  ///
  /// [from] n'est pas vérifié ici : le routeur n'ouvre ensuite que les
  /// chemins internes sûrs (`safeInternalPath`).
  static String withReturn(String path, String? from) {
    if (from == null || from.isEmpty) return path;
    return Uri(path: path, queryParameters: {returnParam: from}).toString();
  }

  /// Le fil d'annonces (adresse racine, utilisée par les liens partagés).
  static const home = '/';
  static const search = '/search';

  // Onglets de la barre du bas.
  static const favorites = '/favorites';
  static const messages = '/messages';
  static const notifications = '/notifications';

  /// Une discussion (plein écran, hors onglets).
  static const conversationPattern = '/messages/:id';
  static String conversation(String id) =>
      '/messages/${Uri.encodeComponent(id)}';

  /// Publication d'une annonce (plein écran, hors onglets).
  static const publish = '/publish';

  // Menu ☰ du fil (plein écran, hors onglets).
  static const profile = '/profile';
  static const settings = '/settings';
  static const help = '/help';

  /// Détail d'une annonce : modèle de route et constructeur d'adresse.
  static const listingPattern = '/listings/:id';
  static String listing(String id) => '/listings/${Uri.encodeComponent(id)}';

  /// Profil public d'un vendeur.
  static const sellerPattern = '/sellers/:id';
  static String seller(String id) => '/sellers/${Uri.encodeComponent(id)}';

  /// Page de diagnostic : déclarée UNIQUEMENT dans le flavor dev.
  static const diagnostics = '/dev/diagnostics';

  /// Galerie du design system : déclarée UNIQUEMENT dans le flavor dev.
  static const gallery = '/dev/gallery';

  /// Routes vers lesquelles on ne redirige jamais après connexion
  /// (évite les boucles). Un utilisateur connecté qui les ouvre est
  /// renvoyé vers sa page d'origine ou le fil.
  static const noReturnRoutes = <String>{
    splash,
    login,
    register,
    forgotPassword,
  };
}
