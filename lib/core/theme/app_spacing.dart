import 'package:flutter/painting.dart';

/// Espacements d'AfriMarket (multiples de 4).
abstract final class AppSpacing {
  /// Espace entre les photos de la grille (effet « bord à bord »).
  static const gridGap = 2.0;

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Marge latérale des pages.
  static const double page = lg;
}

/// Arrondis d'AfriMarket.
abstract final class AppRadius {
  /// Boutons, champs de saisie.
  static const sm = BorderRadius.all(Radius.circular(8));

  /// Cartes, feuilles.
  static const md = BorderRadius.all(Radius.circular(12));

  /// Grandes cartes (ex. « Contacter le vendeur »).
  static const lg = BorderRadius.all(Radius.circular(16));

  /// Pastilles, badges, boutons ronds.
  static const pill = BorderRadius.all(Radius.circular(999));
}
