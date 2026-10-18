import 'package:flutter/material.dart';

/// Typographie d'AfriMarket (ADR 0011).
///
/// - **Bricolage Grotesque**, police de marque intégrée à l'app : logo,
///   titres, prix et boutons uniquement ([brandFamily]) ;
/// - **police du système** (Roboto sur Android, San Francisco sur iOS)
///   pour tout le reste. L'arabe, absent de Bricolage, s'affiche toujours
///   avec la police du système.
///
/// Correspondance avec les maquettes :
/// - displaySmall  : logotype « AfriMarket »
/// - headlineSmall : titre d'une annonce (page détail)
/// - titleLarge    : titres de section (« Description », « Vendeur »)
/// - titleMedium   : prix
/// - bodyLarge     : texte courant
/// - bodyMedium    : texte des cartes d'annonce
/// - bodySmall     : informations secondaires (ville, date)
/// - labelLarge    : boutons
/// - labelSmall    : badges
abstract final class AppTypography {
  /// Famille de la police de marque (déclarée dans `pubspec.yaml`).
  static const brandFamily = 'BricolageGrotesque';

  /// Chiffres de même largeur : les prix restent alignés en colonne.
  static const tabularFigures = [FontFeature.tabularFigures()];

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: brandFamily,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: brandFamily,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: brandFamily,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: brandFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        fontFeatures: tabularFigures,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: primary),
      bodyMedium: TextStyle(fontSize: 15, height: 1.3, color: primary),
      bodySmall: TextStyle(fontSize: 13, height: 1.3, color: secondary),
      labelLarge: TextStyle(
        fontFamily: brandFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
    );
  }
}
