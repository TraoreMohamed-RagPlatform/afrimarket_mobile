import 'dart:math' as math;

import 'package:afrimarket_mobile/core/theme/app_logo_colors.dart';
import 'package:afrimarket_mobile/core/theme/app_typography.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo_intro.dart'
    show AppLogoIntro;
import 'package:flutter/material.dart';

/// Avancement de chaque partie du logo, de 0 (invisible) à 1 (en place).
///
/// Sert à l'animation de l'écran de démarrage ([AppLogoIntro]) ; partout
/// ailleurs le logo est complet ([complete]).
@immutable
final class AppLogoProgress {
  const new({
    this.frame = 1,
    this.basket = 1,
    this.wheels = 1,
    this.block = 1,
    this.cloth = 1,
    this.stripe = 1,
  });

  /// Logo entièrement dessiné.
  static const complete = AppLogoProgress();

  /// Poignée et châssis (tracé progressif).
  final double frame;

  /// Panier (tracé progressif).
  final double basket;

  /// Roues (échelle).
  final double wheels;

  /// Aplat ambre (glissement et opacité).
  final double block;

  /// Pagne qui tombe dans le panier (chute, rotation, opacité).
  final double cloth;

  /// Chevron du pagne (tracé progressif).
  final double stripe;

  @override
  bool operator ==(Object other) =>
      other is AppLogoProgress &&
      other.frame == frame &&
      other.basket == basket &&
      other.wheels == wheels &&
      other.block == block &&
      other.cloth == cloth &&
      other.stripe == stripe;

  @override
  int get hashCode => Object.hash(frame, basket, wheels, block, cloth, stripe);
}

/// Dessine le symbole AfriMarket (ADR 0011) dans un carré de 100 × 100.
///
/// Un chariot au trait, un aplat ambre décalé derrière le panier et un
/// pagne wax plié dans le panier. Dessiné en code (pas d'image) : net à
/// toutes les tailles et coloré selon le thème.
class AppLogoPainter extends CustomPainter {
  const new({required this.colors, this.progress = AppLogoProgress.complete});

  final AppLogoColors colors;
  final AppLogoProgress progress;

  /// Épaisseur du trait, dans le repère 100 × 100.
  static const double strokeWidth = 6;

  static final Path _frame = Path()
    ..moveTo(8, 15)
    ..lineTo(18, 21)
    ..lineTo(31, 64)
    ..lineTo(33, 73)
    ..lineTo(82, 73);

  static final Path _basket = Path()
    ..moveTo(22, 34)
    ..lineTo(86, 34)
    ..lineTo(79, 64)
    ..lineTo(31, 64);

  static final Path _block = Path()
    ..moveTo(29, 39)
    ..lineTo(91, 39)
    ..lineTo(84, 69)
    ..lineTo(36, 69)
    ..close();

  static final Path _stripe = Path()
    ..moveTo(42.5, 25)
    ..lineTo(47, 20)
    ..lineTo(51.5, 25)
    ..lineTo(56, 20)
    ..lineTo(60.5, 25)
    ..lineTo(65, 20)
    ..lineTo(69.5, 25);

  static const _wheels = [Offset(41, 85), Offset(73, 85)];
  static const double _wheelRadius = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress;
    canvas
      ..save()
      ..scale(size.width / 100, size.height / 100)
      // Centre optique du symbole.
      ..translate(1, 0);

    _paintBlock(canvas, p.block);
    _paintCloth(canvas, p.cloth, p.stripe);

    final line = Paint()
      ..color = colors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawPartial(canvas, _frame, p.frame, line);
    _drawPartial(canvas, _basket, p.basket, line);

    if (p.wheels > 0) {
      for (final center in _wheels) {
        canvas
          ..save()
          ..translate(center.dx, center.dy)
          ..scale(p.wheels)
          ..drawCircle(Offset.zero, _wheelRadius, line)
          ..restore();
      }
    }
    canvas.restore();
  }

  void _paintBlock(Canvas canvas, double t) {
    if (t <= 0) return;
    final shift = (1 - t) * -6;
    canvas
      ..save()
      ..translate(shift, shift)
      ..drawPath(_block, Paint()..color = _fade(colors.block, t))
      ..restore();
  }

  void _paintCloth(Canvas canvas, double t, double stripe) {
    if (t <= 0) return;
    // Le pagne tombe d'en haut en pivotant, puis se pose (léger rebond).
    final opacity = (t / 0.35).clamp(0.0, 1.0);
    final fall = _degrees((1 - t) * -16);
    canvas
      ..save()
      ..translate(0, (1 - t) * -30)
      ..translate(55, 54)
      ..rotate(fall)
      ..translate(-55, -54)
      // Inclinaison finale du pagne.
      ..translate(56, 38)
      ..rotate(_degrees(-9))
      ..translate(-56, -38)
      ..drawRRect(
        RRect.fromLTRBR(38, 14, 72, 54, const Radius.circular(2)),
        Paint()..color = _fade(colors.cloth, opacity),
      );
    _drawPartial(
      canvas,
      _stripe,
      stripe,
      Paint()
        ..color = _fade(colors.stripe, opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  static void _drawPartial(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  static double _degrees(double value) => value * math.pi / 180;

  static Color _fade(Color color, double opacity) =>
      color.withValues(alpha: color.a * opacity.clamp(0.0, 1.0));

  @override
  bool shouldRepaint(AppLogoPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.progress != progress;
}

/// Le symbole AfriMarket seul (le chariot), coloré selon le thème.
///
/// Décoratif par défaut : donner [semanticLabel] s'il est affiché sans
/// le nom « AfriMarket ».
class AppLogoMark extends StatelessWidget {
  const new({
    this.size = 32,
    this.progress = AppLogoProgress.complete,
    this.semanticLabel,
    super.key,
  });

  final double size;
  final AppLogoProgress progress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppLogoColors.of(Theme.of(context).brightness);
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: AppLogoPainter(colors: colors, progress: progress),
      ),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: mark);
    return Semantics(label: label, image: true, child: mark);
  }
}

/// Logo officiel horizontal : le chariot, puis « AfriMarket » sur la même
/// ligne, centré sur le panier, de la couleur du pagne (ADR 0011).
///
/// Toujours de gauche à droite, même en arabe : c'est une marque.
class AppLogo extends StatelessWidget {
  const new({this.height = 40, super.key});

  /// Nom de la marque : identique dans toutes les langues.
  static const brandName = 'AfriMarket';

  /// Hauteur du symbole ; le nom et l'espacement en dépendent.
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppLogoLockup(height: height);
  }
}

/// Mise en page du logo horizontal, avec l'avancement de chaque partie.
///
/// [AppLogo] l'utilise complet ; [AppLogoIntro] l'anime.
class AppLogoLockup extends StatelessWidget {
  const new({
    required this.height,
    this.progress = AppLogoProgress.complete,
    this.nameReveal = 1,
    super.key,
  });

  final double height;
  final AppLogoProgress progress;

  /// Part visible du nom, de gauche à droite (0 à 1).
  final double nameReveal;

  /// Taille du nom par rapport au symbole.
  static const double nameScale = 0.47;

  /// Espace entre le symbole et le nom, par rapport au symbole.
  static const double gapScale = 0.11;

  @override
  Widget build(BuildContext context) {
    final colors = AppLogoColors.of(Theme.of(context).brightness);
    final fontSize = height * nameScale;
    final reveal = nameReveal.clamp(0.0, 1.0);

    return Semantics(
      label: AppLogo.brandName,
      container: true,
      child: ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogoMark(size: height, progress: progress),
              SizedBox(width: height * gapScale),
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: reveal,
                  child: Transform.translate(
                    offset: Offset((1 - reveal) * -6, 0),
                    child: Text(
                      AppLogo.brandName,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontFamily: AppTypography.brandFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: fontSize,
                        height: 1,
                        letterSpacing: fontSize * -0.03,
                        color: colors.cloth,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
