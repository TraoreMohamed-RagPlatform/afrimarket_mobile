import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode d'affichage choisi par l'utilisateur.
///
/// `ThemeMode.system` (par défaut) = suivre le réglage du téléphone.
/// Le sélecteur sera ajouté dans la page Paramètres, avec la
/// mémorisation du choix.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Change le mode d'affichage. Sans effet si le mode est identique
  /// (évite de reconstruire toute l'application inutilement).
  void setThemeMode(ThemeMode mode) {
    if (state == mode) return;
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
