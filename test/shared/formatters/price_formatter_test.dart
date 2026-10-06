import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/shared/formatters/price_formatter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les formats numériques utilisent des espaces insécables :
/// on les normalise pour comparer facilement.
String _plain(String text) => text.replaceAll(RegExp('[\u00A0\u202F]'), ' ');

void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));
  final ar = lookupAppLocalizations(const Locale('ar'));

  group('formatPrice', () {
    test('français : 1 400 DH', () {
      expect(_plain(formatPrice(1400, fr)), '1 400 DH');
    });

    test('anglais : 1,400 MAD', () {
      expect(formatPrice(1400, en), '1,400 MAD');
    });

    test('arabe : chiffres occidentaux et devise en arabe', () {
      final text = _plain(formatPrice(1400, ar));

      expect(text, contains('1 400'));
      expect(text, contains('د.م.'));
    });

    test('décimales seulement si nécessaire', () {
      expect(_plain(formatPrice(99.5, fr)), '99,5 DH');
      expect(_plain(formatPrice(100, fr)), '100 DH');
    });

    test('prix nul : Gratuit', () {
      expect(formatPrice(0, fr), fr.priceFree);
      expect(formatPrice(0, ar), ar.priceFree);
    });
  });
}
