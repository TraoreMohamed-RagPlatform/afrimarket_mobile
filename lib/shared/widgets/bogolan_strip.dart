import 'package:flutter/material.dart';

/// Motif signature d'AfriMarket : chevrons et carrés inspirés du bogolan
/// (dessin original, ADR 0011).
///
/// Charte : utilisé SEULEMENT sur l'écran de démarrage, l'en-tête de la
/// connexion / inscription et les écrans vides. Jamais derrière du texte.
///
/// Purement décoratif : ignoré par les lecteurs d'écran.
class BogolanStrip extends StatelessWidget {
  const new({required this.color, this.height = 40, super.key});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: BogolanPainter(color: color)),
      ),
    );
  }
}

/// Dessine le motif en bande horizontale, répété sur toute la largeur.
class BogolanPainter extends CustomPainter {
  const new({required this.color});

  final Color color;

  /// Largeur d'un motif (deux chevrons et trois carrés).
  static const double tileWidth = 48;
  static const double _tileHeight = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..color = color;
    final top = (size.height - _tileHeight) / 2;

    for (var x = 0.0; x < size.width; x += tileWidth) {
      canvas
        ..save()
        ..translate(x, top);
      final zigzag = Path()..moveTo(0, 18);
      for (var i = 1; i <= 6; i++) {
        zigzag.lineTo(i * 8, i.isOdd ? 6 : 18);
      }
      canvas
        ..drawPath(zigzag, line)
        ..drawRect(const Rect.fromLTWH(6, 20, 4, 4), fill)
        ..drawRect(const Rect.fromLTWH(22, 0, 4, 4), fill)
        ..drawRect(const Rect.fromLTWH(38, 20, 4, 4), fill)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(BogolanPainter oldDelegate) => oldDelegate.color != color;
}
