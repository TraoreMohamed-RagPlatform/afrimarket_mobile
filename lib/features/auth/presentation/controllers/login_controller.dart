import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/auth/auth_providers.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/auth_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pilote le formulaire de connexion.
///
/// En cas de succès, la session passe à « connecté » : le routeur ramène
/// alors l'utilisateur à la page demandée (paramètre `from`).
class LoginController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormIdle();

  /// Envoie le formulaire. Ignoré si un envoi est déjà en cours.
  Future<void> submit({required String email, required String password}) async {
    if (state is AuthFormSubmitting) return;
    state = const AuthFormSubmitting();

    final result = await ref.read(loginUseCaseProvider)(
      email: email,
      password: password,
    );
    if (!ref.mounted) return;

    switch (result) {
      case Ok():
        // Session d'abord : l'écran quitte la connexion en réaction à
        // AuthFormSucceeded, la page demandée doit déjà être autorisée.
        ref.read(sessionProvider.notifier).markAuthenticated();
        if (ref.mounted) state = const AuthFormSucceeded();
      case Err(:final failure):
        state = AuthFormFailed(failure);
    }
  }
}

final NotifierProvider<LoginController, AuthFormState> loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, AuthFormState>(
      LoginController.new,
    );
