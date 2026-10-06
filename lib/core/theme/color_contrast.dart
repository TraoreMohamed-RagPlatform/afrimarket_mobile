import 'dart:math';

import 'package:flutter/painting.dart';

/// Contraste minimal d'un texte normal (WCAG 2.1, niveau AA).
const wcagAaNormalText = 4.5;

/// Rapport de contraste entre deux couleurs, selon la formule WCAG 2.1 :
/// (L1 + 0,05) / (L2 + 0,05), avec L1 la luminance la plus élevée.
///
/// Résultat entre 1 (aucun contraste) et 21 (noir sur blanc).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}
