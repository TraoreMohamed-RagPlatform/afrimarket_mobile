import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Champ de recherche de la barre du haut (style Avito / Leboncoin).
///
/// Ce n'est pas un champ de saisie : le toucher ouvre la page de
/// recherche ([onTap]), où se fait la vraie saisie.
class AppSearchLauncher extends StatelessWidget {
  const new({required this.hint, required this.onTap, super.key});

  /// Hauteur minimale de la zone tactile (norme Material).
  static const double minTouchHeight = 48;

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: hint,
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceMuted,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minTouchHeight),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: colors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
