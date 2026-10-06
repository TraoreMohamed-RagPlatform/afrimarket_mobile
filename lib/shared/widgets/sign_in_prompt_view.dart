import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Invitation à se connecter (ADR 0002), affichée à un visiteur dans un
/// onglet personnel (Favoris, Messages, Notifications).
///
/// Après la connexion, l'utilisateur revient sur la page actuelle.
class SignInPromptView extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: context.l10n.signInAction,
      onAction: () {
        final here = GoRouterState.of(context).uri.toString();
        context.go(AppRoutes.loginWithReturn(here));
      },
    );
  }
}
