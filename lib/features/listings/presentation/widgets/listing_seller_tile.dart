import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_seller.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_rating_summary.dart';
import 'package:afrimarket_mobile/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

/// Vendeur d'une annonce : photo, nom, badge « Vérifié », note (ou
/// « Nouveau vendeur »), ancienneté et temps de réponse habituel.
class ListingSellerTile extends StatelessWidget {
  const new({required this.seller, super.key});

  final ListingSeller seller;

  /// Temps de réponse en mots, comme Marketplace ; null s'il est inconnu.
  static String? responseTimeLabel(int? minutes, AppLocalizations l10n) {
    if (minutes == null) return null;
    if (minutes <= 60) return l10n.sellerResponseWithinHour;
    if (minutes <= 6 * 60) return l10n.sellerResponseWithinHours;
    if (minutes <= 24 * 60) return l10n.sellerResponseWithinDay;
    return l10n.sellerResponseWithinDays;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;
    final memberSince = seller.memberSince;
    final response = responseTimeLabel(seller.responseTimeMinutes, l10n);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          name: seller.name,
          imageUrl: seller.avatarUrl,
          verified: seller.isIdentityVerified,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      userText(seller.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: styles.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (seller.isIdentityVerified) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      AppIcons.sealCheck,
                      size: 18,
                      color: colors.brand,
                      semanticLabel: l10n.badgeVerified,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              AppRatingSummary(
                average: seller.averageRating,
                count: seller.ratingCount,
              ),
              if (memberSince != null)
                Text(
                  l10n.sellerMemberSince('${memberSince.year}'),
                  style: styles.bodySmall,
                ),
              if (response != null) Text(response, style: styles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
