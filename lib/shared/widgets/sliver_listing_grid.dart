import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card.dart';
import 'package:flutter/material.dart';

/// Grille d'annonces à 2 colonnes (style Marketplace), à placer dans un
/// `CustomScrollView` : compatible avec le défilement infini.
///
/// La hauteur des cellules = photo carrée + zone de texte mesurée par
/// [ListingCard.textAreaHeight] : elle suit automatiquement la taille de
/// texte du téléphone et toute évolution de la carte.
class SliverListingGrid extends StatelessWidget {
  const new({required this.itemCount, required this.itemBuilder, super.key});

  static const columns = 2;

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final textAreaHeight = ListingCard.textAreaHeight(context);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        const totalGap = AppSpacing.gridGap * (columns - 1);
        final itemWidth = (constraints.crossAxisExtent - totalGap) / columns;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.gridGap,
            mainAxisSpacing: AppSpacing.gridGap,
            mainAxisExtent: itemWidth + textAreaHeight,
          ),
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: itemCount,
          ),
        );
      },
    );
  }
}
