import 'package:flutter/material.dart';

/// Typographie d'AfriMarket, avec la police du SYSTÈME
/// (Roboto sur Android, San Francisco sur iOS) : aucun téléchargement,
/// et l'arabe s'affiche parfaitement.
///
/// Correspondance avec les maquettes :
/// - displaySmall  : titre de la barre du haut (« AfriMarket »)
/// - headlineSmall : titre d'une annonce (page détail)
/// - titleLarge    : titres de section (« Description », « Vendeur »)
/// - titleMedium   : prix
/// - bodyLarge     : texte courant
/// - bodyMedium    : texte des cartes d'annonce
/// - bodySmall     : informations secondaires (ville, date)
/// - labelLarge    : boutons
/// - labelSmall    : badges
abstract final class AppTypography {
  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: primary),
      bodyMedium: TextStyle(fontSize: 15, height: 1.3, color: primary),
      bodySmall: TextStyle(fontSize: 13, height: 1.3, color: secondary),
      labelLarge: TextStyle(
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
