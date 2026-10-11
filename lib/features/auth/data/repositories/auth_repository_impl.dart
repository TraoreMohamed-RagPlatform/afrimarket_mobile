import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:afrimarket_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:afrimarket_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:afrimarket_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Implémentation du contrat [AuthRepository].
///
/// Sécurité (OWASP MASVS - AUTH / STORAGE) :
/// - les tokens reçus vont directement dans le stockage chiffré ;
/// - une session n'est considérée ouverte que si l'enregistrement réussit ;
/// - anti-énumération : « compte inconnu » ne se distingue jamais d'un
///   succès (mot de passe oublié) ou d'un code refusé (réinitialisation) ;
/// - déconnexion : la session locale est effacée AVANT l'appel réseau.
class AuthRepositoryImpl implements AuthRepository {
  const new(this._remote, this._tokens);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) {
    return _openSession(() => _remote.login(email: email, password: password));
  }

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) {
    return _openSession(
      () => _remote.register(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<Result<void>> requestPasswordReset({required String email}) async {
    final result = await guardApiCall<void>(
      () => _remote.requestPasswordReset(email: email),
    );
    // Compte inconnu : même réponse qu'un envoi réussi.
    if (result case Err(failure: NotFoundFailure())) return const Ok(null);
    return result;
  }

  @override
  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final result = await guardApiCall<void>(
      () => _remote.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      ),
    );
    // Compte inconnu : même réponse qu'un code refusé.
    if (result case Err(failure: NotFoundFailure())) {
      return const Err(ValidationFailure());
    }
    return result;
  }

  @override
  Future<void> logout() async {
    final stored = await _tokens.readRefreshToken();
    await _tokens.clear();

    if (stored case Ok(value: final token?) when token.isNotEmpty) {
      // Au mieux : hors ligne, le jeton expirera de lui-même côté serveur.
      await guardApiCall<void>(() => _remote.logout(refreshToken: token));
    }
  }

  Future<Result<AuthUser>> _openSession(
    Future<AuthSessionModel> Function() call,
  ) async {
    final result = await guardApiCall(call);
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final session):
        final saved = await _tokens.saveTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
        return saved.map((_) => session.user);
    }
  }
}
