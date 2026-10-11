import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Cas d'usage : recevoir un code de réinitialisation par e-mail.
class RequestPasswordResetUseCase {
  const new(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) {
    return _repository.requestPasswordReset(email: email.trim());
  }
}
