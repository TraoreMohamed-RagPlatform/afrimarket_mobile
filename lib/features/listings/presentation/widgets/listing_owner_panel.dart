import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Encadré « C'est votre annonce » : remplace « Écrire au vendeur » quand
/// la personne connectée est le vendeur (comme Facebook Marketplace).
///
/// Actions : réserver / remettre en vente, marquer comme vendue. Une
/// annonce vendue n'a plus d'action.
class ListingOwnerPanel extends StatelessWidget {
  const new({
    required this.listing,
    required this.onToggleReserved,
    required this.onMarkSold,
    this.busy = false,
    super.key,
  });

  final ListingDetail listing;
  final VoidCallback onToggleReserved;
  final VoidCallback onMarkSold;

  /// Action en cours : boutons désactivés.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;

    final status = listing.isSold
        ? l10n.ownerStatusSold
        : listing.isReserved
        ? l10n.ownerStatusReserved
        : l10n.ownerStatusActive;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: AppRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.user, color: colors.brand, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(l10n.ownerTitle, style: styles.titleSmall),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(status, style: styles.bodySmall),
            if (!listing.isSold) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('owner-toggle-reserved'),
                      onPressed: busy ? null : onToggleReserved,
                      child: Text(
                        listing.isReserved
                            ? l10n.ownerMarkAvailable
                            : l10n.ownerMarkReserved,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      key: const Key('owner-mark-sold'),
                      onPressed: busy ? null : onMarkSold,
                      child: Text(
                        l10n.ownerMarkSold,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
