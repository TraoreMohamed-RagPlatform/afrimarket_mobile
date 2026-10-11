import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Cas d'usage : choisir un nouveau mot de passe avec le code reçu.
class ResetPasswordUseCase {
  const new(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _repository.resetPassword(
      email: email.trim(),
      code: code.trim(),
      newPassword: newPassword,
    );
  }
}
