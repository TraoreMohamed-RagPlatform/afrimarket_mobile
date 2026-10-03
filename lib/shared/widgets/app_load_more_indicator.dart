import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Petit indicateur en bas d'une liste, pendant le chargement de la page
/// suivante (défilement infini). Les squelettes, eux, servent au premier
/// chargement.
class AppLoadMoreIndicator extends StatelessWidget {
  const new({super.key});

  static const double _size = 24;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loadingLabel,
      excludeSemantics: true,
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: SizedBox.square(
            dimension: _size,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
