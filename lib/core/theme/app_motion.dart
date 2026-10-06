import 'package:flutter/widgets.dart';

/// Durées et courbes d'animation d'AfriMarket.
///
/// Toute animation de l'app utilise ces valeurs (cohérence visuelle) et
/// respecte le réglage « Réduire les animations » du téléphone
/// ([reduceMotion], [resolve]).
abstract final class AppMotion {
  /// Petits changements d'état (bouton, icône).
  static const fast = Duration(milliseconds: 150);

  /// Transitions courantes (apparition, déplacement).
  static const normal = Duration(milliseconds: 250);

  /// Grandes transitions (page, feuille).
  static const slow = Duration(milliseconds: 400);

  /// Pulsation des squelettes de chargement (un aller).
  static const skeletonPulse = Duration(milliseconds: 900);

  /// Courbe standard : départ rapide, arrivée douce.
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Vrai si l'utilisateur a demandé de réduire les animations.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// [duration], ou zéro si les animations sont réduites.
  static Duration resolve(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;
}
