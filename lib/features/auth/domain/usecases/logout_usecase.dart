import 'package:afrimarket_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Cas d'usage : se déconnecter de cet appareil.
class LogoutUseCase {
  const new(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
