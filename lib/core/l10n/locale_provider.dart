import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Langue choisie par l'utilisateur.
///
/// `null` = suivre la langue du téléphone (valeur par défaut).
/// Le sélecteur de langue sera ajouté dans la page Paramètres,
/// avec la mémorisation du choix.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  /// Change la langue de l'app. `null` = langue du téléphone.
  ///
  /// Une langue non prise en charge est ignorée.
  void setLocale(Locale? locale) {
    if (locale != null && !isSupported(locale)) return;
    state = locale;
  }

  /// Indique si la langue fait partie des langues de l'app.
  static bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
