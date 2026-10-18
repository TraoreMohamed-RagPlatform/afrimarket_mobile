import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Date de publication d'une annonce, comme sur Marketplace :
/// « Publiée à l'instant », « il y a 12 min », « il y a 3 h »,
/// « hier », « il y a 5 jours », puis la date (« le 3 oct. 2026 »).
///
/// Une date dans le futur (horloge du téléphone en retard) compte comme
/// « à l'instant ».
String formatListingAge(
  DateTime createdAt,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  final age = (now ?? DateTime.now()).difference(createdAt);

  if (age.inMinutes < 1) return l10n.listingPublishedJustNow;
  if (age.inHours < 1) return l10n.listingPublishedMinutes(age.inMinutes);
  if (age.inDays < 1) return l10n.listingPublishedHours(age.inHours);
  if (age.inDays < 30) return l10n.listingPublishedDays(age.inDays);

  final date = DateFormat.yMMMd(l10n.localeName).format(createdAt.toLocal());
  return l10n.listingPublishedOn(date);
}
