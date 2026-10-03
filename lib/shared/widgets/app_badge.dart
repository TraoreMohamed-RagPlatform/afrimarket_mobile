import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Types de badges d'AfriMarket.
enum AppBadgeType {
  /// Annonce publiée il y a moins de 24 heures.
  recent,

  /// Vendeur dont l'identité a été vérifiée.
  verified,
}

/// Petite pastille d'information (« Récent », « ✓ Vérifié »).
///
/// Couleurs issues du thème : contraste WCAG AA garanti en clair et sombre.
class AppBadge extends StatelessWidget {
  const new(this.type, {super.key});

  final AppBadgeType type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final (label, background, foreground, icon) = switch (type) {
      AppBadgeType.recent => (
        l10n.badgeRecent,
        colors.accent,
        colors.onAccent,
        null,
      ),
      AppBadgeType.verified => (
        l10n.badgeVerified,
        colors.brandSoft,
        colors.onBrandSoft,
        Icons.verified_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
