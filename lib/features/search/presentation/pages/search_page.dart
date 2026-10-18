import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Recherche d'annonces (ouverte depuis le champ du fil).
///
/// PROVISOIRE : la saisie, les filtres et les résultats arrivent avec la
/// fonctionnalité Recherche.
class SearchPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchHint)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(l10n.searchComingSoon, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
