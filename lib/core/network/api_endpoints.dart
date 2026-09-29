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
}
