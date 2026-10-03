import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Formate une note moyenne avec une décimale : « 4,8 » (fr, ar), « 4.8 » (en).
///
/// Comme pour les prix, l'arabe utilise les chiffres occidentaux
/// (usage marocain).
String formatRating(double rating, AppLocalizations l10n) {
  final numberLocale = l10n.localeName.startsWith('ar')
      ? 'fr'
      : l10n.localeName;
  return NumberFormat('0.0', numberLocale).format(rating);
}
