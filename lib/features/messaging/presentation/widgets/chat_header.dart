import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/core/theme/app_typography.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/price_formatter.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_network_image.dart';
import 'package:afrimarket_mobile/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

/// Titre de la discussion : photo et nom de l'autre personne.
class ChatTitle extends StatelessWidget {
  const new({required this.person, super.key});

  final ConversationPerson? person;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final other = person;
    if (other == null) return Text(l10n.chatTitleFallback);

    final name = other.name == null
        ? l10n.messagesDeletedAccount
        : userText(other.name!);
    return Row(
      children: [
        UserAvatar(
          name: other.name ?? '',
          imageUrl: other.avatarUrl,
          size: AvatarSize.small,
          verified: other.isIdentityVerified,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bandeau de l'annonce, sous le titre : photo, titre, prix, statut. Mène
/// à l'annonce.
class ChatListingBar extends StatelessWidget {
  const new({required this.listing, required this.onTap, super.key});

  static const double photoSize = 48;

  final ConversationListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;
    final status = switch (listing.status) {
      ConversationListingStatus.available => l10n.chatListingAvailable,
      ConversationListingStatus.reserved => l10n.listingStatusReserved,
      ConversationListingStatus.sold => l10n.listingStatusSold,
      ConversationListingStatus.unavailable => l10n.chatListingUnavailable,
    };

    return Material(
      color: colors.surfaceMuted,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          link: true,
          hint: l10n.chatOpenListing,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.page,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.sm,
                  child: SizedBox.square(
                    dimension: photoSize,
                    child: AppNetworkImage(url: listing.photoUrl),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userText(listing.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: styles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatPrice(listing.price, l10n),
                              style: TextStyle(
                                fontFamily: AppTypography.brandFamily,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                                fontFeatures: AppTypography.tabularFigures,
                              ),
                            ),
                            TextSpan(text: ' · $status'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: styles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  AppIcons.caretRight,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Conseil de sécurité en haut de la discussion, que l'on peut masquer.
class ChatSafetyTip extends StatelessWidget {
  const new({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(AppIcons.shieldCheck, size: 20, color: colors.brand),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: l10n.chatSafetyTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    TextSpan(text: ' ${l10n.chatSafetyMessage}'),
                  ],
                ),
                style: styles.bodySmall,
              ),
            ),
            IconButton(
              tooltip: l10n.chatSafetyDismiss,
              onPressed: onDismiss,
              icon: Icon(AppIcons.x, size: 18, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
