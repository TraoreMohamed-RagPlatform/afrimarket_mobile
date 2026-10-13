import 'package:afrimarket_mobile/core/theme/app_palette.dart';
import 'package:flutter/widgets.dart';

/// Couleurs du logo AfriMarket selon le thème (ADR 0011).
///
/// - [line] : trait du chariot, noir en clair et blanc en sombre ;
/// - [cloth] : pagne dans le panier ET nom « AfriMarket » (toujours la même
///   couleur) ;
/// - [block] : aplat ambre décalé derrière le panier ;
/// - [stripe] : chevron dessiné sur le pagne ;
/// - [canvas] : fond de l'écran de démarrage (crème en clair, comme
///   l'icône de l'app).
@immutable
final class AppLogoColors {
  const new({
    required this.line,
    required this.cloth,
    required this.block,
    required this.stripe,
    required this.canvas,
  });

  /// Mode clair : trait noir, pagne et nom en terre cuite.
  static const light = AppLogoColors(
    line: AppPalette.ink,
    cloth: AppPalette.terracotta600,
    block: AppPalette.amber200,
    stripe: AppPalette.cream,
    canvas: AppPalette.cream,
  );

  /// Mode sombre : trait blanc, terre cuite plus claire pour rester lisible
  /// (contraste 4,4:1 sur le fond sombre).
  static const dark = AppLogoColors(
    line: AppPalette.neutral50Dark,
    cloth: AppPalette.terracotta400,
    block: AppPalette.amber200,
    stripe: AppPalette.cream,
    canvas: AppPalette.neutral900,
  );

  final Color line;
  final Color cloth;
  final Color block;
  final Color stripe;
  final Color canvas;

  /// Couleurs adaptées à [brightness].
  static AppLogoColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
