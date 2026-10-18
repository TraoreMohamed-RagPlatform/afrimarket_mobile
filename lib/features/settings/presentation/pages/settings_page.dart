import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Paramètres (menu ☰). Accessible sans compte : langue et thème.
///
/// PROVISOIRE : le choix de la langue et du thème arrive avec la fonctionnalité
/// Paramètres.
class SettingsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(l10n.settingsComingSoon, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
