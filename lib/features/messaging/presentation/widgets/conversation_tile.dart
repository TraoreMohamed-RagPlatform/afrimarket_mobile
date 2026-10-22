import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/core/theme/app_typography.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/message_time.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/price_formatter.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_badge.dart';
import 'package:afrimarket_mobile/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

/// Une discussion dans la liste (maquette page 6) : photo de l'annonce,
/// personne, heure, annonce et statut, début du dernier message, non-lus.
class ConversationTile extends StatelessWidget {
  const new({required this.conversation, required this.onTap, super.key});

  /// Côté de la photo de l'annonce.
  static const double photoSize = 56;

  final ConversationSummary conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;
    final item = conversation;
    final unread = item.unreadCount > 0;
    final person = item.otherUser;
    final listing = item.listing;
    final last = item.lastMessage;

    final name = person.name == null
        ? l10n.messagesDeletedAccount
        : userText(person.name!);
    final listingLine = listing == null
        ? l10n.messagesListingDeleted
        : '${userText(listing.title)} · ${formatPrice(listing.price, l10n)}';
    final preview = last == null
        ? null
        : last.isMine
        ? l10n.messagesFromMe(userText(last.text))
        : userText(last.text);
    final badge = switch (listing?.status) {
      ConversationListingStatus.reserved => AppBadgeType.reserved,
      ConversationListingStatus.sold => AppBadgeType.sold,
      _ => null,
    };

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 80),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.sm,
                child: SizedBox.square(
                  dimension: photoSize,
                  child: listing == null
                      ? ColoredBox(
                          color: colors.imagePlaceholder,
                          child: Icon(
                            AppIcons.imageBroken,
                            color: colors.textSecondary,
                          ),
                        )
                      : AppNetworkImage(url: listing.photoUrl),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: styles.bodyLarge?.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: person.isDeleted
                                  ? colors.textSecondary
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                        if (last != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            MessageTime.inList(last.sentAt, l10n),
                            style: styles.labelSmall?.copyWith(
                              color: unread
                                  ? colors.brand
                                  : colors.textSecondary,
                              fontWeight: unread ? FontWeight.w700 : null,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            listingLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: styles.bodySmall,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          AppBadge(badge),
                        ],
                      ],
                    ),
                    if (preview != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: styles.bodyMedium?.copyWith(
                                fontWeight: unread ? FontWeight.w700 : null,
                                color: unread
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: AppSpacing.sm),
                            UnreadPill(count: item.unreadCount),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nombre de messages non lus (pastille terre cuite).
class UnreadPill extends StatelessWidget {
  const new({required this.count, super.key});

  /// Au-delà, « 99+ ».
  static const int max = 99;

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: context.l10n.unreadCount(count),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xs + 2,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.brand,
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          count > max ? '$max+' : '$count',
          style: context.textStyles.labelSmall?.copyWith(
            color: colors.onBrand,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ),
    );
  }
}
