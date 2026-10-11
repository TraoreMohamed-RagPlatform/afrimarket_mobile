import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:afrimarket_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Cas d'usage : se connecter.
class LoginUseCase {
  const new(this._repository);

  final AuthRepository _repository;

  /// L'e-mail est nettoyé (espaces) ; le mot de passe est envoyé tel quel.
  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email.trim(), password: password);
  }
}
