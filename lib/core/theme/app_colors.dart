import 'package:afrimarket_mobile/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Couleurs SÉMANTIQUES d'AfriMarket : chaque couleur a un rôle.
///
/// Les pages utilisent uniquement ces couleurs (jamais [AppPalette]),
/// ce qui rend le mode sombre automatique.
///
/// Accessibilité : chaque paire texte / fond respecte un contraste
/// d'au moins 4,5:1 (WCAG 2.1 AA), vérifié par les tests.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const new({
    required this.brand,
    required this.onBrand,
    required this.brandSoft,
    required this.onBrandSoft,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.imagePlaceholder,
    required this.success,
    required this.error,
    required this.onError,
  });

  /// Couleurs du mode clair.
  static const light = AppColors(
    brand: AppPalette.terracotta600,
    onBrand: AppPalette.white,
    brandSoft: AppPalette.terracotta50,
    onBrandSoft: AppPalette.terracotta600,
    accent: AppPalette.amber200,
    onAccent: AppPalette.amber900,
    background: AppPalette.white,
    surface: AppPalette.white,
    surfaceMuted: AppPalette.neutral100,
    textPrimary: AppPalette.neutral900,
    textSecondary: AppPalette.neutral600,
    border: AppPalette.neutral200,
    imagePlaceholder: AppPalette.neutral100,
    success: AppPalette.success,
    error: AppPalette.error,
    onError: AppPalette.white,
  );

  /// Couleurs du mode sombre.
  ///
  /// La terre cuite foncée serait peu lisible sur fond noir : on utilise
  /// une terre cuite claire avec un texte foncé (recommandation Material 3).
  static const dark = AppColors(
    brand: AppPalette.terracotta200,
    onBrand: AppPalette.terracotta900,
    brandSoft: AppPalette.terracotta800,
    onBrandSoft: AppPalette.terracotta100,
    accent: AppPalette.amber200,
    onAccent: AppPalette.amber900,
    background: AppPalette.neutral900,
    surface: AppPalette.neutral850,
    surfaceMuted: AppPalette.neutral700,
    textPrimary: AppPalette.neutral50Dark,
    textSecondary: AppPalette.neutral500,
    border: AppPalette.neutral800,
    imagePlaceholder: AppPalette.neutral700,
    success: AppPalette.successLight,
    error: AppPalette.errorLight,
    onError: AppPalette.errorDark,
  );

  /// Boutons principaux, onglet actif, bouton ➕.
  final Color brand;
  final Color onBrand;

  /// Fond teinté discret (pastille active) et son texte.
  final Color brandSoft;
  final Color onBrandSoft;

  /// Badges « Récent », promotions.
  final Color accent;
  final Color onAccent;

  /// Fond de page.
  final Color background;

  /// Cartes, feuilles, barres.
  final Color surface;

  /// Pastilles et boutons gris (secondaires).
  final Color surfaceMuted;

  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  /// Fond affiché pendant le chargement d'une photo.
  final Color imagePlaceholder;

  final Color success;
  final Color error;
  final Color onError;

  @override
  AppColors copyWith({
    Color? brand,
    Color? onBrand,
    Color? brandSoft,
    Color? onBrandSoft,
    Color? accent,
    Color? onAccent,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? imagePlaceholder,
    Color? success,
    Color? error,
    Color? onError,
  }) {
    return AppColors(
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandSoft: brandSoft ?? this.brandSoft,
      onBrandSoft: onBrandSoft ?? this.onBrandSoft,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      success: success ?? this.success,
      error: error ?? this.error,
      onError: onError ?? this.onError,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brand: mix(brand, other.brand),
      onBrand: mix(onBrand, other.onBrand),
      brandSoft: mix(brandSoft, other.brandSoft),
      onBrandSoft: mix(onBrandSoft, other.onBrandSoft),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      border: mix(border, other.border),
      imagePlaceholder: mix(imagePlaceholder, other.imagePlaceholder),
      success: mix(success, other.success),
      error: mix(error, other.error),
      onError: mix(onError, other.onError),
    );
  }
}
