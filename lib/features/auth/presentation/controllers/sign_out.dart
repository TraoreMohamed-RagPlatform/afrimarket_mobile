import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/auth/auth_providers.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Déconnexion complète de cet appareil.
///
/// Sécurité (OWASP MASVS - AUTH) :
/// 1. les pages protégées sont masquées immédiatement ;
/// 2. la session locale est effacée ;
/// 3. le serveur révoque le jeton (au mieux : une coupure réseau
///    n'empêche jamais de se déconnecter).
class SignOut {
  const new(this._session, this._logout);

  final SessionNotifier _session;
  final LogoutUseCase _logout;

  Future<void> call() async {
    _session.markSignedOut();
    await _logout();
  }
}

final signOutProvider = Provider<SignOut>(
  (ref) => SignOut(
    ref.watch(sessionProvider.notifier),
    ref.watch(logoutUseCaseProvider),
  ),
);
