import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Textes français, lus depuis les fichiers ARB.
final AppLocalizations fr = lookupAppLocalizations(const Locale('fr'));

/// Place le « téléphone » de test en français.
void useFrenchDevice(WidgetTester tester) {
  tester.platformDispatcher.localesTestValue = const [Locale('fr')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

/// Application minimale avec les traductions, pour tester une page seule.
Widget localizedApp(Widget home, {Locale locale = const Locale('fr')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
