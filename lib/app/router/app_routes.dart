/// Liste centralisée des routes de l'application.
///
/// Aucun chemin de navigation ne doit être écrit en dur ailleurs.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';

  /// Page de diagnostic : déclarée UNIQUEMENT dans le flavor dev.
  static const diagnostics = '/dev/diagnostics';

  /// Routes accessibles sans être connecté.
  static const publicRoutes = <String>{login, diagnostics};

  /// Routes vers lesquelles on ne redirige jamais après connexion
  /// (évite les boucles).
  static const noReturnRoutes = <String>{splash, login};
}
