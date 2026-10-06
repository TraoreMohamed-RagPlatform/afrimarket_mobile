import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Une pastille de [AppChipBar].
@immutable
class AppChipItem {
  const new({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.hasDropdown = false,
  });

  final String label;
  final VoidCallback onTap;

  /// Pastille active (fond teinté, annoncée « sélectionnée »).
  final bool selected;

  /// Affiche une flèche ▼ (la pastille ouvre un choix).
  final bool hasDropdown;
}

/// Rangée de pastilles défilante, avec une action fixe en fin de ligne.
///
/// Générique : le widget ne connaît pas les pastilles qu'il affiche
/// (« Vendre », « Acheter », filtres de recherche...). Ajouter une pastille
/// ne demande aucune modification ici.
///
/// Widget autonome : il fournit sa propre surface Material (fonctionne avec
/// ou sans Scaffold).
///
/// - zones tactiles de 48 px et état « sélectionné » annoncé (ChoiceChip) ;
/// - défilement horizontal si les pastilles ne tiennent pas (arabe,
///   grande taille de texte) ;
/// - [trailing] reste visible hors du défilement (ex. bouton 📍).
class AppChipBar extends StatelessWidget {
  const new({required this.items, this.trailing, super.key});

  final List<AppChipItem> items;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelStyle = context.textStyles.labelLarge;
    final trailingWidget = trailing;

    return Material(
      type: MaterialType.transparency,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.sm,
              ),
              child: Row(
                spacing: AppSpacing.xs,
                children: [
                  for (final item in items)
                    ChoiceChip(
                      selected: item.selected,
                      onSelected: (_) => item.onTap(),
                      labelStyle: labelStyle?.copyWith(
                        color: item.selected
                            ? colors.onBrandSoft
                            : colors.textPrimary,
                      ),
                      label: item.hasDropdown
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item.label),
                                const Icon(Icons.expand_more, size: 18),
                              ],
                            )
                          : Text(item.label),
                    ),
                ],
              ),
            ),
          ),
          if (trailingWidget != null) ...[
            SizedBox(
              height: 24,
              child: VerticalDivider(width: 1, color: colors.border),
            ),
            trailingWidget,
          ],
        ],
      ),
    );
  }
}
