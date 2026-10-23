import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:afrimarket_mobile/features/notifications/presentation/notification_text.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Une notification (maquette page 11, style Facebook) : photo de
/// l'annonce avec l'icône du type, texte, date ; non lue : fond teinté et
/// point. Glisser vers le début pour la retirer.
class NotificationTile extends StatelessWidget {
  const new({
    required this.notification,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  static const double leadingSize = 56;
  static const double _badgeSize = 24;
  static const double _dotSize = 10;

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;
    final item = notification;
    final unread = !item.read;
    final text = NotificationText.message(item, l10n);
    final time = NotificationText.time(item.createdAt, l10n);
    final photo = item.listing?.photoUrl;

    return Dismissible(
      key: ValueKey('notification-${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: ColoredBox(
        color: colors.error,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(AppIcons.trash, color: colors.onError),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.notificationDelete,
                style: styles.labelLarge?.copyWith(color: colors.onError),
              ),
            ],
          ),
        ),
      ),
      child: Semantics(
        label: unread
            ? '$text, $time, ${l10n.notificationUnread}'
            : '$text, $time',
        excludeSemantics: true,
        button: true,
        onTap: onTap,
        customSemanticsActions: {
          CustomSemanticsAction(label: l10n.notificationDelete): onDelete,
        },
        child: Material(
          color: unread ? colors.brandSoft : colors.background,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 80),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.page,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: leadingSize + _badgeSize / 4,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.sm,
                            child: SizedBox.square(
                              dimension: leadingSize,
                              child: photo == null
                                  ? ColoredBox(
                                      color: colors.surfaceMuted,
                                      child: Icon(
                                        NotificationText.icon(item.kind),
                                        color: colors.brand,
                                        size: 28,
                                      ),
                                    )
                                  : AppNetworkImage(url: photo),
                            ),
                          ),
                          if (photo != null)
                            PositionedDirectional(
                              end: 0,
                              bottom: 0,
                              child: Container(
                                width: _badgeSize,
                                height: _badgeSize,
                                decoration: BoxDecoration(
                                  color: colors.brand,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: unread
                                        ? colors.brandSoft
                                        : colors.background,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  NotificationText.icon(item.kind),
                                  size: 13,
                                  color: colors.onBrand,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: styles.bodyMedium?.copyWith(
                              fontWeight: unread ? FontWeight.w600 : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            time,
                            style: styles.bodySmall?.copyWith(
                              color: unread
                                  ? colors.brand
                                  : colors.textSecondary,
                              fontWeight: unread ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: _dotSize,
                        height: _dotSize,
                        decoration: BoxDecoration(
                          color: colors.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
