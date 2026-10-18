/// Liste centralisée des routes de l'API AfriMarket.
///
/// Aucun chemin d'API ne doit être écrit en dur ailleurs dans l'app.
/// Les chemins sont relatifs à `AppConfig.apiBaseUrl`.
abstract final class ApiEndpoints {
  // Santé du serveur
  static const health = '/api/health';

  // Authentification
  static const register = '/api/auth/register';
  static const login = '/api/auth/login';
  static const logout = '/api/auth/logout';
  static const me = '/api/auth/me';
  static const refreshToken = '/api/auth/refresh-token';
  static const verifyEmail = '/api/auth/verify-email';
  static const confirmEmail = '/api/auth/confirm-email';
  static const forgotPassword = '/api/auth/forgot-password';
  static const resetPassword = '/api/auth/reset-password';
  static const changePassword = '/api/auth/change-password';
  static const logoutAll = '/api/auth/logout-all';

  // Annonces (lecture publique)
  static const listings = '/api/listings';

  /// Une annonce. [id] est encodé pour l'adresse.
  static String listing(String id) => '$listings/${Uri.encodeComponent(id)}';

  /// Annonces similaires à une annonce.
  static String similarListings(String id) => '${listing(id)}/similar';

  /// Numéro du vendeur d'une annonce (connexion requise).
  static String listingContact(String id) => '${listing(id)}/contact';

  /// Signaler une annonce (connexion requise).
  static String reportListing(String id) => '${listing(id)}/report';

  // Favoris (connexion requise)
  static const favorites = '/api/favorites';
  static String favorite(String listingId) =>
      '$favorites/${Uri.encodeComponent(listingId)}';
  static String favoriteCheck(String listingId) =>
      '$favorites/check/${Uri.encodeComponent(listingId)}';

  // Messagerie (connexion requise)
  static const messages = '/api/messages';
  static const conversations = '/api/messages/conversations';
  static const unreadMessages = '/api/messages/unread-count';

  // Notifications (connexion requise)
  static const unreadNotifications = '/api/notifications/unread-count';

  /// Options de filtre, dont les catégories.
  static const filters = '/api/filters';

  // Support
  static const contactForm = '/api/support/contact-form';

  /// Routes qui ne doivent JAMAIS recevoir de token d'accès
  /// ni déclencher de refresh automatique.
  static const publicAuthRoutes = <String>{
    register,
    login,
    refreshToken,
    verifyEmail,
    confirmEmail,
    forgotPassword,
    resetPassword,
  };

  /// Routes qui exigent une preuve App Check (anti-robots) : le serveur
  /// refuse ces requêtes sans en-tête `X-Firebase-AppCheck` valide.
  static const attestedRoutes = <String>{register, login, contactForm};
}
