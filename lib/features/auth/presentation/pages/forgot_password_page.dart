import 'dart:async';

import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/auth/domain/validation/auth_validators.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:afrimarket_mobile/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:afrimarket_mobile/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:afrimarket_mobile/features/auth/presentation/widgets/auth_messages.dart';
import 'package:afrimarket_mobile/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Écran « mot de passe oublié », en deux étapes :
/// 1. l'adresse e-mail, pour recevoir un code à 6 chiffres ;
/// 2. le code et le nouveau mot de passe.
///
/// Le serveur ferme alors toutes les sessions : l'utilisateur revient à la
/// connexion.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  ForgotPasswordController get _controller =>
      ref.read(forgotPasswordControllerProvider.notifier);

  Future<void> _requestCode() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await _controller.requestCode(_email.text);
  }

  Future<void> _reset() async {
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await _controller.resetPassword(
      code: _code.text,
      newPassword: _password.text,
    );
  }

  void _onStateChanged(
    ForgotPasswordState? previous,
    ForgotPasswordState next,
  ) {
    if (next.step == ForgotPasswordStep.done &&
        previous?.step != ForgotPasswordStep.done) {
      TextInput.finishAutofillContext();
      context
        ..showAppSnackBar(context.l10n.resetPasswordDone)
        ..go(AppRoutes.login);
    } else if (next.codeResent && !(previous?.codeResent ?? false)) {
      context.showAppSnackBar(context.l10n.forgotCodeResent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(forgotPasswordControllerProvider);
    ref.listen(forgotPasswordControllerProvider, _onStateChanged);

    return AuthFormLayout(
      title: l10n.forgotTitle,
      child: switch (state.step) {
        ForgotPasswordStep.email => _buildEmailStep(state),
        ForgotPasswordStep.code ||
        ForgotPasswordStep.done => _buildResetStep(state),
      },
    );
  }

  Widget _buildEmailStep(ForgotPasswordState state) {
    final l10n = context.l10n;
    final busy = state.isBusy;
    final failure = state.failure;

    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.forgotIntro, style: context.textStyles.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
          if (failure != null) ...[
            AuthErrorBanner(failure.message(l10n)),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField(
            label: l10n.authEmailLabel,
            controller: _email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: authFieldValidator(AuthValidators.email, l10n),
            onSubmitted: (_) => unawaited(_requestCode()),
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthSubmitButton(
            label: l10n.forgotSendCode,
            loading: busy,
            onPressed: () => unawaited(_requestCode()),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(ForgotPasswordState state) {
    final l10n = context.l10n;
    final busy = state.isBusy;
    final failure = state.failure;

    return AutofillGroup(
      child: Form(
        key: _resetFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.forgotCodeSent(userText(state.email)),
              style: context.textStyles.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (failure != null) ...[
              AuthErrorBanner(AuthFailureMessages.reset(failure, l10n)),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppTextField(
              label: l10n.authCodeLabel,
              controller: _code,
              enabled: !busy,
              sensitive: true,
              maxLength: AuthValidators.codeLength,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.oneTimeCode],
              validator: authFieldValidator(AuthValidators.resetCode, l10n),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.authNewPasswordLabel,
              helper: l10n.authPasswordHelper,
              controller: _password,
              enabled: !busy,
              isPassword: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: authFieldValidator(AuthValidators.newPassword, l10n),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.authConfirmPasswordLabel,
              controller: _confirmation,
              enabled: !busy,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) => AuthValidators.confirmation(
                value,
                _password.text,
              )?.message(l10n),
              onSubmitted: (_) => unawaited(_reset()),
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthSubmitButton(
              label: l10n.forgotResetSubmit,
              loading: state.pending == ForgotPasswordAction.reset,
              onPressed: () => unawaited(_reset()),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () => unawaited(_controller.resendCode()),
                  child: Text(l10n.forgotResendCode),
                ),
                TextButton(
                  onPressed: busy ? null : () => _controller.changeEmail(),
                  child: Text(l10n.forgotChangeEmail),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
