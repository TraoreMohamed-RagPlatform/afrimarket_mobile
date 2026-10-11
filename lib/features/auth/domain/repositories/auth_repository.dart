import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';

/// Contrat : authentification et sessions (S2).
///
/// Défini dans le domaine, implémenté dans la couche data. L'implémentation
/// enregistre elle-même les tokens : ils ne remontent jamais jusqu'à
/// l'interface.
abstract interface class AuthRepository {
  /// Connexion. En cas de succès, la session est enregistrée.
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  });

  /// Inscription. En cas de succès, la session est enregistrée.
  Future<Result<AuthUser>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  });

  /// Demande un code de réinitialisation par e-mail.
  ///
  /// Anti-énumération : réussit aussi pour un e-mail inconnu.
  Future<Result<void>> requestPasswordReset({required String email});

  /// Remplace le mot de passe à l'aide du code reçu.
  ///
  /// Le serveur ferme alors toutes les sessions : il faut se reconnecter.
  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Déconnexion de cet appareil : efface la session locale, puis demande
  /// au serveur de révoquer le jeton (au mieux). N'échoue jamais.
  Future<void> logout();
}
