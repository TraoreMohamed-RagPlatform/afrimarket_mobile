import 'package:flutter/material.dart';

/// Titre de section (« Description », « Vendeur › »).
///
/// Deux variantes, exclusives :
/// - [actionLabel] + [onAction] : lien à droite (ex. « Voir plus ») ;
/// - [onTap] : tout le titre est cliquable, avec une flèche ›
///   (inversée automatiquement en arabe).
///
/// Widget autonome : fournit sa propre surface Material.
class AppSectionHeader extends StatelessWidget {
  const new({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.onTap,
    super.key,
  }) : assert(
         onTap == null || actionLabel == null,
         'Choisir soit un lien (actionLabel), soit un titre cliquable (onTap).',
       );

  /// Hauteur minimale de la zone tactile.
  static const double minHeight = 48;

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = actionLabel;
    final tapHandler = onTap;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: textTheme.titleLarge),
            ),
          ),
          if (label != null)
            TextButton(onPressed: onAction, child: Text(label)),
          if (tapHandler != null) const Icon(Icons.chevron_right),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: tapHandler == null
          ? row
          : Semantics(
              button: true,
              child: InkWell(onTap: tapHandler, child: row),
            ),
    );
  }
}
