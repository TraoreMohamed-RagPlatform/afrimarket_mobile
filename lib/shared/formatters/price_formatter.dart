import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Formate un prix en dirhams selon la langue de l'app.
///
/// - français : « 1 400 DH »
/// - anglais  : « 1,400 MAD »
/// - arabe    : « 1 400 د.م. » (chiffres occidentaux, usage marocain)
/// - prix <= 0 : « Gratuit »
///
/// Jusqu'à 2 décimales, uniquement si nécessaire (« 99,5 DH »).
String formatPrice(num price, AppLocalizations l10n) {
  if (price <= 0) return l10n.priceFree;

  // Au Maroc, les prix sont écrits en chiffres occidentaux, même en arabe :
  // on utilise donc le format numérique français pour l'arabe.
  final numberLocale = l10n.localeName.startsWith('ar')
      ? 'fr'
      : l10n.localeName;
  final formatter = NumberFormat.decimalPattern(numberLocale)
    ..maximumFractionDigits = 2;

  return l10n.priceAmount(formatter.format(price));
}
