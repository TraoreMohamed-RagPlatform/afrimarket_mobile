import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/auth_gate.dart';
import 'package:afrimarket_mobile/shared/widgets/sign_in_prompt_view.dart';
import 'package:flutter/material.dart';

/// Onglet Notifications.
///
/// PROVISOIRE : la liste des notifications arrive avec sa fonctionnalité.
class NotificationsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navNotifications)),
      body: AuthGate(
        signInPrompt: SignInPromptView(
          icon: Icons.notifications_none,
          title: l10n.signInNotificationsTitle,
          message: l10n.signInNotificationsMessage,
        ),
        child: Center(child: Text(l10n.notificationsComingSoon)),
      ),
    );
  }
}
