import 'dart:async';

import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/auth/domain/validation/auth_validators.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/auth_form_state.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/register_controller.dart';
import 'package:afrimarket_mobile/features/auth/presentation/sign_in_navigation.dart';
import 'package:afrimarket_mobile/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:afrimarket_mobile/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:afrimarket_mobile/features/auth/presentation/widgets/auth_messages.dart';
import 'package:afrimarket_mobile/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Écran d'inscription.
///
/// Le compte créé, l'utilisateur est connecté et ramené à [returnTo]
/// (page demandée avant la connexion) ou au fil.
class RegisterPage extends ConsumerStatefulWidget {
  const new({this.returnTo, super.key});

  /// Page à rouvrir après l'inscription (paramètre `from`).
  final String? returnTo;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(registerControllerProvider.notifier)
        .submit(
          fullName: _fullName.text,
          username: _username.text,
          email: _email.text,
          password: _password.text,
        );
  }

  /// Retour à la connexion : la page précédente si elle existe.
  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.withReturn(AppRoutes.login, widget.returnTo));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(registerControllerProvider);
    final submitting = state is AuthFormSubmitting;

    ref.listen(registerControllerProvider, (previous, next) {
      if (next is AuthFormSucceeded && previous is! AuthFormSucceeded) {
        TextInput.finishAutofillContext();
        // Ouverte depuis la connexion : celle-ci prend le relais.
        if (context.canPop()) {
          context.pop(true);
        } else {
          leaveAuthAfterSignIn(context, widget.returnTo);
        }
      }
    });

    return AuthFormLayout(
      title: l10n.registerTitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.registerIntro, style: context.textStyles.bodyLarge),
              const SizedBox(height: AppSpacing.xl),
              if (state case AuthFormFailed(:final failure)) ...[
                AuthErrorBanner(AuthFailureMessages.register(failure, l10n)),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppTextField(
                label: l10n.authFullNameLabel,
                controller: _fullName,
                enabled: !submitting,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: authFieldValidator(AuthValidators.fullName, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.authUsernameLabel,
                helper: l10n.authUsernameHelper,
                controller: _username,
                enabled: !submitting,
                sensitive: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                validator: authFieldValidator(AuthValidators.username, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.authEmailLabel,
                controller: _email,
                enabled: !submitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: authFieldValidator(AuthValidators.email, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.authPasswordLabel,
                helper: l10n.authPasswordHelper,
                controller: _password,
                enabled: !submitting,
                isPassword: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: authFieldValidator(AuthValidators.newPassword, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.authConfirmPasswordLabel,
                controller: _confirmation,
                enabled: !submitting,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => AuthValidators.confirmation(
                  value,
                  _password.text,
                )?.message(l10n),
                onSubmitted: (_) => unawaited(_submit()),
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthSubmitButton(
                label: l10n.registerSubmit,
                loading: submitting,
                onPressed: () => unawaited(_submit()),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.registerHaveAccount),
                  TextButton(
                    onPressed: submitting ? null : _goToLogin,
                    child: Text(l10n.loginSubmit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
