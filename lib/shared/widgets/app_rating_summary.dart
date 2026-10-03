import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/rating_formatter.dart';
import 'package:flutter/material.dart';

/// Résumé de la note d'un vendeur : « ★ 4,8 · 12 avis ».
///
/// Sans avis, affiche « Nouveau vendeur » plutôt que « Aucun avis »,
/// pour ne pas pénaliser les vendeurs qui débutent.
class AppRatingSummary extends StatelessWidget {
  const new({required this.average, required this.count, super.key});

  /// Note moyenne sur 5 (ignorée si [count] vaut 0).
  final double average;

  /// Nombre d'avis reçus.
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final style = context.textStyles.bodySmall;

    if (count <= 0) {
      return Text(l10n.sellerNew, style: style);
    }

    final rating = formatRating(average, l10n);
    return Semantics(
      label: '${l10n.ratingAverage(rating)}, ${l10n.ratingCount(count)}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 16, color: colors.brand),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              '$rating · ${l10n.ratingCount(count)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
