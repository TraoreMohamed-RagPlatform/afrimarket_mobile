import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Texte, icône et date d'une notification, dans la langue de l'app.
///
/// Le texte est construit à partir du type (et du titre de l'annonce) :
/// le texte enregistré par le serveur, en français, n'est affiché que pour
/// les messages de l'équipe ([NotificationKind.system]).
abstract final class NotificationText {
  static String message(AppNotification item, AppLocalizations l10n) {
    final title = item.listing == null ? null : userText(item.listing!.title);
    return switch (item.kind) {
      NotificationKind.listingInterest when title != null =>
        l10n.notificationListingInterest(title),
      NotificationKind.ratingReceived when title != null =>
        l10n.notificationRatingReceived(title),
      NotificationKind.ratingReceived => l10n.notificationRatingNoListing,
      NotificationKind.listingSold when title != null =>
        l10n.notificationListingSold(title),
      NotificationKind.listingUpdated when title != null =>
        l10n.notificationListingUpdated(title),
      NotificationKind.message => l10n.notificationMessage,
      _ => _serverText(item),
    };
  }

  /// Texte du serveur (titre et message), isolé comme un texte saisi.
  static String _serverText(AppNotification item) {
    final parts = [item.title, item.message].where((part) => part.isNotEmpty);
    return userText(parts.join(' — '));
  }

  static IconData icon(NotificationKind kind) => switch (kind) {
    NotificationKind.listingInterest => AppIconsFill.bookmarkSimple,
    NotificationKind.ratingReceived => AppIconsFill.star,
    NotificationKind.listingSold => AppIconsFill.checkCircle,
    NotificationKind.listingUpdated => AppIcons.arrowClockwise,
    NotificationKind.message => AppIconsFill.chatCircle,
    NotificationKind.system => AppIcons.megaphone,
  };

  /// « À l'instant », « il y a 5 min », « il y a 3 h », « Hier »,
  /// « il y a 4 jours », puis la date.
  static String time(
    DateTime createdAt,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    final age = (now ?? DateTime.now()).difference(createdAt);
    if (age.inMinutes < 1) return l10n.notificationTimeJustNow;
    if (age.inHours < 1) return l10n.notificationTimeMinutes(age.inMinutes);
    if (age.inDays < 1) return l10n.notificationTimeHours(age.inHours);
    if (age.inDays == 1) return l10n.notificationTimeYesterday;
    if (age.inDays < 7) return l10n.notificationTimeDays(age.inDays);
    return DateFormat.yMMMd(l10n.localeName).format(createdAt.toLocal());
  }
}
