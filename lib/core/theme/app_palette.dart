import 'package:afrimarket_mobile/core/theme/app_colors.dart' show AppColors;
import 'package:flutter/painting.dart';

/// Couleurs BRUTES de la marque AfriMarket.
///
/// Ne jamais les utiliser directement dans les pages : passer par les
/// couleurs sémantiques ([AppColors]), qui gèrent le mode clair et sombre.
abstract final class AppPalette {
  // Terre cuite : couleur principale de la marque.
  static const terracotta50 = Color(0xFFFAECE7);
  static const terracotta100 = Color(0xFFF5C4B3);
  static const terracotta200 = Color(0xFFF0997B);
  static const terracotta400 = Color(0xFFD85A30);
  static const terracotta600 = Color(0xFF993C1D);
  static const terracotta800 = Color(0xFF712B13);
  static const terracotta900 = Color(0xFF4A1B0C);

  // Ambre : couleur d'accent (badges, promotions).
  static const amber50 = Color(0xFFFAEEDA);
  static const amber200 = Color(0xFFEF9F27);
  static const amber900 = Color(0xFF412402);

  // Neutres.
  static const white = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFF7F7F6);
  static const neutral100 = Color(0xFFEEEEEC);
  static const neutral200 = Color(0xFFDADAD7);
  static const neutral400 = Color(0xFF9A9A96);
  static const neutral500 = Color(0xFFB4B2A9);
  static const neutral600 = Color(0xFF65655F);
  static const neutral700 = Color(0xFF2A2A27);
  static const neutral800 = Color(0xFF3A3A36);
  static const neutral850 = Color(0xFF1C1C1A);
  static const neutral900 = Color(0xFF121211);
  static const neutral50Dark = Color(0xFFF2F2F0);

  // États.
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFF81C784);
  static const error = Color(0xFFB3261E);
  static const errorLight = Color(0xFFF2B8B5);
  static const errorDark = Color(0xFF601410);
}
