import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/auth_gate.dart';
import 'package:afrimarket_mobile/shared/widgets/sign_in_prompt_view.dart';
import 'package:flutter/material.dart';

/// Onglet Favoris.
///
/// PROVISOIRE : la liste des annonces enregistrées arrive avec la
/// fonctionnalité Favoris.
class FavoritesPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navFavorites)),
      body: AuthGate(
        signInPrompt: SignInPromptView(
          icon: Icons.star_border,
          title: l10n.signInFavoritesTitle,
          message: l10n.signInFavoritesMessage,
        ),
        child: Center(child: Text(l10n.favoritesComingSoon)),
      ),
    );
  }
}
