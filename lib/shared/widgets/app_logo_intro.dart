import 'package:afrimarket_mobile/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';

/// Logo animé de l'écran de démarrage (1,2 s, ADR 0011).
///
/// 1. le chariot se dessine (poignée et châssis, puis panier, puis roues) ;
/// 2. l'aplat ambre glisse et se cale en décalé ;
/// 3. le pagne tombe dans le panier avec un léger rebond, puis son
///    chevron se dessine ;
/// 4. « AfriMarket » se dévoile de gauche à droite.
///
/// `animation` va de 0 à 1 ; c'est l'écran qui la pilote (et qui la saute
/// si « Réduire les animations » est activé).
class AppLogoIntro extends AnimatedWidget {
  const new({required Animation<double> animation, this.height = 72, super.key})
    : super(listenable: animation);

  /// Durée totale de l'animation.
  static const duration = Duration(milliseconds: 1200);

  static const _frame = Interval(0, 0.35, curve: Curves.easeOutCubic);
  static const _basket = Interval(0.10, 0.40, curve: Curves.easeOutCubic);
  static const _wheels = Interval(0.275, 0.46, curve: Curves.easeOutBack);
  static const _block = Interval(0.25, 0.52, curve: Curves.easeOutCubic);
  static const _cloth = Interval(0.42, 0.77, curve: Curves.easeOutBack);
  static const _stripe = Interval(0.68, 0.87, curve: Curves.easeOutCubic);
  static const _name = Interval(0.63, 0.97, curve: Curves.easeOutCubic);

  /// Hauteur du symbole.
  final double height;

  Animation<double> get _animation => listenable as Animation<double>;

  /// Avancement de chaque partie du logo à l'instant [t] (0 à 1).
  static AppLogoProgress progressAt(double t) => AppLogoProgress(
    frame: _frame.transform(t),
    basket: _basket.transform(t),
    wheels: _wheels.transform(t),
    block: _block.transform(t),
    cloth: _cloth.transform(t),
    stripe: _stripe.transform(t),
  );

  /// Part visible du nom à l'instant [t].
  static double nameRevealAt(double t) => _name.transform(t);

  @override
  Widget build(BuildContext context) {
    final t = _animation.value;
    return AppLogoLockup(
      height: height,
      progress: progressAt(t),
      nameReveal: nameRevealAt(t),
    );
  }
}
