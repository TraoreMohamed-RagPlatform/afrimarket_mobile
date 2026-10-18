import 'dart:async';

import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/dev_tools.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/auth/domain/validation/auth_validators.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/auth_form_state.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/login_controller.dart';
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

/// Écran de connexion (e-mail et mot de passe).
///
/// Après la connexion, le routeur ramène l'utilisateur à [returnTo]
/// (page demandée avant la connexion) ou au fil.
class LoginPage extends ConsumerStatefulWidget {
  const new({this.returnTo, super.key});

  /// Page à rouvrir après la connexion (paramètre `from`).
  final String? returnTo;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(loginControllerProvider.notifier)
        .submit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = ref.watch(appConfigProvider);
    final state = ref.watch(loginControllerProvider);
    final submitting = state is AuthFormSubmitting;

    // Propose au gestionnaire de mots de passe d'enregistrer l'identifiant.
    ref.listen(loginControllerProvider, (previous, next) {
      if (next is AuthFormSucceeded) TextInput.finishAutofillContext();
    });

    return AuthFormLayout(
      title: l10n.loginTitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.loginIntro, style: context.textStyles.bodyLarge),
              const SizedBox(height: AppSpacing.xl),
              if (state case AuthFormFailed(:final failure)) ...[
                AuthErrorBanner(AuthFailureMessages.login(failure, l10n)),
                const SizedBox(height: AppSpacing.lg),
              ],
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
                controller: _password,
                enabled: !submitting,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: authFieldValidator(
                  AuthValidators.currentPassword,
                  l10n,
                ),
                onSubmitted: (_) => unawaited(_submit()),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: submitting
                      ? null
                      : () => unawaited(context.push(AppRoutes.forgotPassword)),
                  child: Text(l10n.loginForgotPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AuthSubmitButton(
                label: l10n.loginSubmit,
                loading: submitting,
                onPressed: () => unawaited(_submit()),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.loginNoAccount),
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () => unawaited(
                            context.push(
                              AppRoutes.withReturn(
                                AppRoutes.register,
                                widget.returnTo,
                              ),
                            ),
                          ),
                    child: Text(l10n.loginCreateAccount),
                  ),
                ],
              ),
              if (devToolsVisible(config.flavor)) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.diagnostics),
                  icon: const Icon(AppIcons.wrench),
                  label: Text(l10n.devDiagnosticsButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
