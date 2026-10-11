import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/auth/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Étapes du parcours « mot de passe oublié ».
enum ForgotPasswordStep {
  /// Saisie de l'adresse e-mail.
  email,

  /// Saisie du code reçu et du nouveau mot de passe.
  code,

  /// Mot de passe changé : retour à la connexion.
  done,
}

/// Action en cours ou échouée, pour afficher le bon message.
enum ForgotPasswordAction { requestCode, resendCode, reset }

/// État du parcours « mot de passe oublié ».
@immutable
final class ForgotPasswordState {
  const new({
    this.step = ForgotPasswordStep.email,
    this.email = '',
    this.pending,
    this.failure,
    this.codeResent = false,
  });

  final ForgotPasswordStep step;

  /// Adresse saisie à la première étape (réutilisée ensuite).
  final String email;

  /// Action en cours d'envoi, sinon `null`.
  final ForgotPasswordAction? pending;

  /// Dernier échec, sinon `null`.
  final Failure? failure;

  /// Un nouveau code vient d'être demandé avec succès.
  final bool codeResent;

  bool get isBusy => pending != null;
}

/// Pilote le parcours « mot de passe oublié » (code à 6 chiffres).
///
/// Sécurité (anti-énumération) : la deuxième étape s'affiche que l'adresse
/// corresponde à un compte ou non ; le message reste le même.
class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  /// Étape 1 : demande un code pour [email].
  Future<void> requestCode(String email) async {
    if (state.isBusy) return;
    final address = email.trim();
    state = ForgotPasswordState(
      email: address,
      pending: ForgotPasswordAction.requestCode,
    );

    final result = await ref.read(requestPasswordResetUseCaseProvider)(
      email: address,
    );
    if (!ref.mounted) return;

    state = switch (result) {
      Ok() => ForgotPasswordState(
        step: ForgotPasswordStep.code,
        email: address,
      ),
      Err(:final failure) => ForgotPasswordState(
        email: address,
        failure: failure,
      ),
    };
  }

  /// Étape 2 : demande un nouveau code pour la même adresse.
  Future<void> resendCode() async {
    if (state.isBusy || state.step != ForgotPasswordStep.code) return;
    final email = state.email;
    state = ForgotPasswordState(
      step: ForgotPasswordStep.code,
      email: email,
      pending: ForgotPasswordAction.resendCode,
    );

    final result = await ref.read(requestPasswordResetUseCaseProvider)(
      email: email,
    );
    if (!ref.mounted) return;

    state = ForgotPasswordState(
      step: ForgotPasswordStep.code,
      email: email,
      failure: switch (result) {
        Ok() => null,
        Err(:final failure) => failure,
      },
      codeResent: result.isOk,
    );
  }

  /// Étape 2 : remplace le mot de passe avec le [code] reçu.
  Future<void> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    if (state.isBusy || state.step != ForgotPasswordStep.code) return;
    final email = state.email;
    state = ForgotPasswordState(
      step: ForgotPasswordStep.code,
      email: email,
      pending: ForgotPasswordAction.reset,
    );

    final result = await ref.read(resetPasswordUseCaseProvider)(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    if (!ref.mounted) return;

    state = switch (result) {
      Ok() => ForgotPasswordState(step: ForgotPasswordStep.done, email: email),
      Err(:final failure) => ForgotPasswordState(
        step: ForgotPasswordStep.code,
        email: email,
        failure: failure,
      ),
    };
  }

  /// Revient à la saisie de l'adresse e-mail (adresse conservée).
  void changeEmail() {
    if (state.isBusy) return;
    state = ForgotPasswordState(email: state.email);
  }
}

final NotifierProvider<ForgotPasswordController, ForgotPasswordState>
forgotPasswordControllerProvider =
    NotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
      ForgotPasswordController.new,
    );
