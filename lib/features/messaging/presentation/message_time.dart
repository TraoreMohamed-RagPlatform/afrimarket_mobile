import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Dates des messages, comme sur Marketplace.
abstract final class MessageTime {
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _dayBefore(DateTime day) =>
      DateTime(day.year, day.month, day.day - 1);

  /// Liste des discussions : « 10:42 », « Hier », « lun. », « 12 oct. »,
  /// puis la date complète les années précédentes.
  static String inList(
    DateTime sentAt,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    final local = sentAt.toLocal();
    final today = (now ?? DateTime.now()).toLocal();
    final locale = l10n.localeName;

    if (_sameDay(local, today)) return DateFormat.Hm(locale).format(local);
    if (_sameDay(local, _dayBefore(today))) return l10n.messagesYesterday;
    if (today.difference(local).inDays < 7) {
      return DateFormat.E(locale).format(local);
    }
    if (local.year == today.year) return DateFormat.MMMd(locale).format(local);
    return DateFormat.yMMMd(locale).format(local);
  }

  /// Séparateur de jour dans une discussion : « Aujourd'hui », « Hier »,
  /// « lundi 12 octobre », puis avec l'année.
  static String day(DateTime sentAt, AppLocalizations l10n, {DateTime? now}) {
    final local = sentAt.toLocal();
    final today = (now ?? DateTime.now()).toLocal();
    final locale = l10n.localeName;

    if (_sameDay(local, today)) return l10n.chatToday;
    if (_sameDay(local, _dayBefore(today))) return l10n.messagesYesterday;
    if (local.year == today.year) {
      return DateFormat.MMMMEEEEd(locale).format(local);
    }
    return DateFormat.yMMMMd(locale).format(local);
  }

  /// Heure sous une bulle : « 10:42 ».
  static String time(DateTime sentAt, AppLocalizations l10n) =>
      DateFormat.Hm(l10n.localeName).format(sentAt.toLocal());

  /// Même jour (heure locale) ?
  static bool sameDay(DateTime a, DateTime b) =>
      _sameDay(a.toLocal(), b.toLocal());
}
