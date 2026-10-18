import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Aide et support (menu ☰). Accessible sans compte.
///
/// PROVISOIRE : la FAQ et le formulaire de contact arrivent avec la
/// fonctionnalité Support.
class HelpPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(l10n.helpComingSoon, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
