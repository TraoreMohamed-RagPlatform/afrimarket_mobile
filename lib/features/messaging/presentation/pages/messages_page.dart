import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/auth_gate.dart';
import 'package:afrimarket_mobile/shared/widgets/sign_in_prompt_view.dart';
import 'package:flutter/material.dart';

/// Onglet Messages.
///
/// PROVISOIRE : la liste des conversations arrive avec la messagerie.
class MessagesPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMessages)),
      body: AuthGate(
        signInPrompt: SignInPromptView(
          icon: Icons.chat_bubble_outline,
          title: l10n.signInMessagesTitle,
          message: l10n.signInMessagesMessage,
        ),
        child: Center(child: Text(l10n.messagesComingSoon)),
      ),
    );
  }
}
