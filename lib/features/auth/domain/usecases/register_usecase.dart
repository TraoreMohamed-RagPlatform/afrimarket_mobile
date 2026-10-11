import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:afrimarket_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Cas d'usage : créer un compte.
class RegisterUseCase {
  const new(this._repository);

  final AuthRepository _repository;

  /// Les champs texte sont nettoyés (espaces) ; jamais le mot de passe.
  Future<Result<AuthUser>> call({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) {
    return _repository.register(
      fullName: fullName.trim(),
      username: username.trim(),
      email: email.trim(),
      password: password,
    );
  }
}
