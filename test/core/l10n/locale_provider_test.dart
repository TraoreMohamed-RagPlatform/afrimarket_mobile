import 'package:afrimarket_mobile/core/l10n/locale_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('LocaleNotifier', () {
    test('suit la langue du téléphone par défaut (null)', () {
      expect(container.read(localeProvider), isNull);
    });

    test('change de langue', () {
      container.read(localeProvider.notifier).setLocale(const Locale('ar'));

      expect(container.read(localeProvider), const Locale('ar'));
    });

    test('refuse une langue non prise en charge', () {
      container.read(localeProvider.notifier).setLocale(const Locale('es'));

      expect(container.read(localeProvider), isNull);
    });

    test('null revient à la langue du téléphone', () {
      container.read(localeProvider.notifier)
        ..setLocale(const Locale('en'))
        ..setLocale(null);

      expect(container.read(localeProvider), isNull);
    });
  });
}
