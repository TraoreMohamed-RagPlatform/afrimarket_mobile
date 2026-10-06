import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/shared/formatters/rating_formatter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));
  final ar = lookupAppLocalizations(const Locale('ar'));

  test('une décimale, séparateur de la langue', () {
    expect(formatRating(4.8, fr), '4,8');
    expect(formatRating(4.8, en), '4.8');
    expect(formatRating(5, fr), '5,0');
  });

  test('arabe : chiffres occidentaux', () {
    expect(formatRating(4.8, ar), '4,8');
  });
}
